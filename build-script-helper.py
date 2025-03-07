#!/usr/bin/env python3
##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift.org open source project
##
## Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0 with Runtime Library Exception
##
## See https://swift.org/LICENSE.txt for license information
## See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
##
##===----------------------------------------------------------------------===##

from __future__ import print_function

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import List, Optional, Union

# -----------------------------------------------------------------------------
# General utilities


def fatal_error(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def printerr(message: str) -> None:
    print(message, file=sys.stderr)


def check_call(
    cmd: List[Union[str, Path]], verbose: bool, env=os.environ, **kwargs
) -> None:
    if verbose:
        print(" ".join([escape_cmd_arg(arg) for arg in cmd]))
    subprocess.check_call(cmd, env=env, stderr=subprocess.STDOUT, **kwargs)


def check_output(
    cmd: List[Union[str, Path]], verbose, env=os.environ, capture_stderr=True, **kwargs
) -> str:
    if verbose:
        print(" ".join([escape_cmd_arg(arg) for arg in cmd]))
    if capture_stderr:
        stderr = subprocess.STDOUT
    else:
        stderr = subprocess.DEVNULL
    return subprocess.check_output(
        cmd, env=env, stderr=stderr, encoding="utf-8", **kwargs
    )


def escape_cmd_arg(arg: Union[str, Path]) -> str:
    arg = str(arg)
    if '"' in arg or " " in arg:
        return '"%s"' % arg.replace('"', '\\"')
    else:
        return arg


# -----------------------------------------------------------------------------
# SwiftPM wrappers


def get_build_target(swift_exec: Path, cross_compile_config: Optional[Path]) -> str:
    """Returns the target-triple of the current machine or for cross-compilation."""
    command = [swift_exec, "-print-target-info"]
    if cross_compile_config:
        cross_compile_json = json.load(open(cross_compile_config))
        command += ["-target", cross_compile_json["target"]]
    target_info_json = subprocess.check_output(
        command, stderr=subprocess.PIPE, universal_newlines=True
    ).strip()
    target_info = json.loads(target_info_json)
    if "-apple-macosx" in target_info["target"]["unversionedTriple"]:
        return target_info["target"]["unversionedTriple"]
    return target_info["target"]["triple"]


def get_swiftpm_options(
    swift_exec: Path,
    package_path: Path,
    build_path: Path,
    multiroot_data_file: Optional[Path],
    configuration: str,
    cross_compile_host: Optional[str],
    cross_compile_config: Optional[Path],
    verbose: bool,
) -> List[Union[str, Path]]:
    args: List[Union[str, Path]] = [
        "--package-path",
        package_path,
        "--configuration",
        configuration,
        "--scratch-path",
        build_path,
    ]
    if multiroot_data_file:
        args += ["--multiroot-data-file", multiroot_data_file]
    if verbose:
        args += ["--verbose"]
    build_target = get_build_target(
        swift_exec, cross_compile_config=cross_compile_config
    )
    build_os = build_target.split("-")[2]
    if not build_os.startswith("macosx"):
        # Library rpath for swift, dispatch, Foundation, etc. when installing
        args += [
            "-Xlinker",
            "-rpath",
            "-Xlinker",
            "$ORIGIN/../lib/swift/" + build_os,
        ]
        args += ['--disable-local-rpath']

    if cross_compile_host:
        if build_os.startswith("macosx") and cross_compile_host.startswith("macosx-"):
            args += ["--arch", "x86_64", "--arch", "arm64"]
        else:
            fatal_error("cannot cross-compile for %s" % cross_compile_host)

    return args


def get_swiftpm_environment_variables(action: str):
    env = dict(os.environ)
    env["SWIFTCI_USE_LOCAL_DEPS"] = "1"
    if action == "install":
        env["SWIFTFORMAT_CI_INSTALL"] = "1"
    return env


def invoke_swiftpm(
    package_path: Path,
    swift_exec: Path,
    action: str,
    product: str,
    build_path: Path,
    multiroot_data_file: Optional[Path],
    configuration: str,
    cross_compile_host: Optional[str],
    cross_compile_config: Optional[Path],
    env,
    verbose: bool,
):
    """
    Build or test a single SwiftPM product.
    """
    args = [swift_exec, action]
    args += get_swiftpm_options(
        swift_exec=swift_exec,
        package_path=package_path,
        build_path=build_path,
        multiroot_data_file=multiroot_data_file,
        configuration=configuration,
        cross_compile_host=cross_compile_host,
        cross_compile_config=cross_compile_config,
        verbose=verbose,
    )
    if action == "test":
        args += ["--test-product", product, "--disable-testable-imports"]
    else:
        args += ["--product", product]

    check_call(args, env=env, verbose=verbose)


# -----------------------------------------------------------------------------
# Actions


def build(args: argparse.Namespace) -> None:
    print("** Building swift-format **")
    env = get_swiftpm_environment_variables(args.action)
    invoke_swiftpm(
        package_path=args.package_path,
        swift_exec=args.swift_exec,
        action="build",
        product="swift-format",
        build_path=args.build_path,
        multiroot_data_file=args.multiroot_data_file,
        configuration=args.configuration,
        cross_compile_host=args.cross_compile_host,
        cross_compile_config=args.cross_compile_config,
        env=env,
        verbose=args.verbose,
    )


def test(args: argparse.Namespace) -> None:
    print("** Testing swift-format **")
    env = get_swiftpm_environment_variables(args.action)
    invoke_swiftpm(
        package_path=args.package_path,
        swift_exec=args.swift_exec,
        action="test",
        product="swift-formatPackageTests",
        build_path=args.build_path,
        multiroot_data_file=args.multiroot_data_file,
        configuration=args.configuration,
        cross_compile_host=args.cross_compile_host,
        cross_compile_config=args.cross_compile_config,
        env=env,
        verbose=args.verbose,
    )


def install(args: argparse.Namespace) -> None:
    build(args)

    print("** Installing swift-format **")

    env = get_swiftpm_environment_variables(args.action)
    swiftpm_args = get_swiftpm_options(
        swift_exec=args.swift_exec,
        package_path=args.package_path,
        build_path=args.build_path,
        multiroot_data_file=args.multiroot_data_file,
        configuration=args.configuration,
        cross_compile_host=args.cross_compile_host,
        cross_compile_config=args.cross_compile_config,
        verbose=args.verbose,
    )
    cmd = [args.swift_exec, "build", "--show-bin-path"] + swiftpm_args
    bin_path = check_output(
        cmd, env=env, capture_stderr=False, verbose=args.verbose
    ).strip()

    for prefix in args.install_prefixes:
        cmd = [
            "rsync",
            "-a",
            Path(bin_path) / "swift-format",
            prefix / "bin",
        ]
        check_call(cmd, verbose=args.verbose)


# -----------------------------------------------------------------------------
# Argument parsing


def add_common_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--package-path", default="")
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="log executed commands"
    )
    parser.add_argument("--configuration", default="debug")
    parser.add_argument("--build-path", type=Path, default=None)
    parser.add_argument(
        "--multiroot-data-file",
        type=Path,
        help="Path to an Xcode workspace to create a unified build of SwiftSyntax with other projects.",
    )
    parser.add_argument(
        "--toolchain",
        required=True,
        type=Path,
        help="the toolchain to use when building this package",
    )
    parser.add_argument(
        "--cross-compile-host", help="cross-compile for another host instead"
    )
    parser.add_argument(
        "--cross-compile-config",
        help="an SPM JSON destination file containing Swift cross-compilation flags",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="build-script-helper.py")
    if sys.version_info >= (3, 7, 0):
        subparsers = parser.add_subparsers(title="subcommands", dest="action", required=True, metavar="action")
    else:
        subparsers = parser.add_subparsers(title="subcommands", dest="action", metavar="action")

    build_parser = subparsers.add_parser("build", help="build the package")
    add_common_args(build_parser)

    test_parser = subparsers.add_parser("test", help="test the package")
    add_common_args(test_parser)

    install_parser = subparsers.add_parser("install", help="install the package")
    add_common_args(install_parser)
    install_parser.add_argument(
        "--prefix",
        dest="install_prefixes",
        nargs="*",
        type=Path,
        metavar="PATHS",
        help="install path",
    )

    parsed = parser.parse_args(sys.argv[1:])

    parsed.swift_exec = parsed.toolchain / "bin" / "swift"

    # Convert package_path to absolute path, relative to root of repo.
    repo_path = Path(__file__).parent
    parsed.package_path = (repo_path / parsed.package_path).resolve()

    if not parsed.build_path:
        parsed.build_path = parsed.package_path / ".build"

    return parsed


def main():
    args = parse_args()

    # The test action creates its own build. No need to build if we are just testing.
    if args.action == "build":
        build(args)
    elif args.action == "test":
        test(args)
    elif args.action == "install":
        install(args)
    else:
        fatal_error(f"unknown action '{args.action}'")


if __name__ == "__main__":
    main()
