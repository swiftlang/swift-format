#!/usr/bin/env python3

"""
  This source file is part of the Swift.org open source project
  Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
  Licensed under Apache License v2.0 with Runtime Library Exception
  See https://swift.org/LICENSE.txt for license information
  See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
 ------------------------------------------------------------------------------
 This is a helper script for the main swift repository's build-script.py that
 knows how to build and install the stress tester utilities given a swift
 workspace.
"""

from __future__ import print_function

import argparse
import sys
import os, platform
import subprocess

# -----------------------------------------------------------------------------
# General utilities

def printerr(message: str):
  print(message, file=sys.stderr)

def check_call(cmd, verbose, env=os.environ, **kwargs):
  if verbose:
    print(' '.join([escape_cmd_arg(arg) for arg in cmd]))
  return subprocess.check_call(cmd, env=env, stderr=subprocess.STDOUT, **kwargs)

def check_output(cmd, verbose, env=os.environ, capture_stderr=True, **kwargs):
  if verbose:
    print(' '.join([escape_cmd_arg(arg) for arg in cmd]))
  if capture_stderr:
    stderr = subprocess.STDOUT
  else:
    stderr = subprocess.DEVNULL
  return subprocess.check_output(cmd, env=env, stderr=stderr, encoding='utf-8', **kwargs)

def escape_cmd_arg(arg):
  if '"' in arg or ' ' in arg:
    return '"%s"' % arg.replace('"', '\\"')
  else:
    return arg

# -----------------------------------------------------------------------------
# SwiftPM wrappers

def update_swiftpm_dependencies(package_path, swift_exec, build_path, env, verbose):
  args = [swift_exec, 'package', '--package-path', package_path, '--scratch-path', build_path, 'update']
  check_call(args, env=env, verbose=verbose)

def invoke_swift(package_path, swift_exec, action, products, build_path, multiroot_data_file, configuration, env, verbose):
  # Until rdar://53881101 is implemented, we cannot request a build of multiple 
  # targets simultaneously. For now, just build one product after the other.
  for product in products:
    invoke_swift_single_product(package_path, swift_exec, action, product, build_path, multiroot_data_file, configuration, env, verbose)

def get_swiftpm_options(package_path, build_path, multiroot_data_file, configuration, verbose):
  args = [ 
    '--package-path', package_path, 
    '--configuration', configuration, 
    '--scratch-path', build_path
  ]
  if multiroot_data_file:
    args += ['--multiroot-data-file', multiroot_data_file]
  if verbose:
    args += ['--verbose']
  if platform.system() == 'Darwin':
    args += [
        '-Xlinker', '-rpath', '-Xlinker', '/usr/lib/swift',
        '-Xlinker', '-rpath', '-Xlinker', '@executable_path/../lib/swift/macosx',
        '-Xlinker', '-rpath', '-Xlinker', '@executable_path/../lib/swift-5.5/macosx',
    ]
  return args

def get_swiftpm_environment_variables(no_local_deps):
  env = dict(os.environ)
  if not no_local_deps:
    env['SWIFTCI_USE_LOCAL_DEPS'] = "1"
  return env


def invoke_swift_single_product(package_path, swift_exec, action, product, build_path, multiroot_data_file, configuration, env, verbose):
  args = [swift_exec, action]
  args += get_swiftpm_options(package_path, build_path, multiroot_data_file, configuration, verbose)
  if action == 'test':
    args += [
      '--test-product', product,
      '--disable-testable-imports'
    ]
  else:
    args += ['--product', product]

  check_call(args, env=env, verbose=verbose)

def generate_xcodeproj(package_path, swift_exec, env, verbose):
  package_name = os.path.basename(package_path)
  xcodeproj_path = os.path.join(package_path, '%s.xcodeproj' % package_name)
  args = [swift_exec, 'package', '--package-path', package_path, 'generate-xcodeproj', '--output', xcodeproj_path]
  check_call(args, env=env, verbose=verbose)

# -----------------------------------------------------------------------------
# Argument parsing


def parse_args(args):
  parser = argparse.ArgumentParser(prog='build-script-helper.py')

  parser.add_argument('--package-path', default='')
  parser.add_argument('-v', '--verbose', action='store_true', help='log executed commands')
  parser.add_argument('--prefix', dest='install_prefixes', nargs='*', metavar='PATHS', help='install path')
  parser.add_argument('--configuration', default='debug')
  parser.add_argument('--build-path', default=None)
  parser.add_argument('--multiroot-data-file', help='Path to an Xcode workspace to create a unified build of SwiftSyntax with other projects.')
  parser.add_argument('--toolchain', required=True, help='the toolchain to use when building this package')
  parser.add_argument('--update', action='store_true', help='update all SwiftPM dependencies')
  parser.add_argument('--no-local-deps', action='store_true', help='use normal remote dependencies when building')
  parser.add_argument('build_actions', help="Extra actions to perform. Can be any number of the following", choices=['all', 'build', 'test', 'generate-xcodeproj', 'install'], nargs="*", default=['build'])

  parsed = parser.parse_args(args)

  parsed.swift_exec = os.path.join(parsed.toolchain, 'bin', 'swift')

  # Convert package_path to absolute path, relative to root of repo.
  repo_path = os.path.dirname(__file__)
  parsed.package_path = os.path.realpath(
                        os.path.join(repo_path, parsed.package_path))

  if not parsed.build_path:
    parsed.build_path = os.path.join(parsed.package_path, '.build')

  return parsed

def should_run_action(action_name, selected_actions):
  if action_name in selected_actions:
    return True
  elif "all" in selected_actions:
    return True
  else:
    return False

def run(args):
  package_name = os.path.basename(args.package_path)

  env = get_swiftpm_environment_variables(no_local_deps=args.no_local_deps)
  # Use local dependencies (i.e. checked out next swift-format).
  
  if args.update:
    print("** Updating dependencies of %s **" % package_name)
    try:
      update_swiftpm_dependencies(package_path=args.package_path,
        swift_exec=args.swift_exec,
        build_path=args.build_path,
        env=env,
        verbose=args.verbose)
    except subprocess.CalledProcessError as e:
      printerr('FAIL: Updating dependencies of %s failed' % package_name)
      printerr('Executing: %s' % ' '.join(e.cmd))
      sys.exit(1)

  # The test action creates its own build. No need to build if we are just testing.
  if should_run_action('build', args.build_actions) or should_run_action('install', args.build_actions):
    print("** Building %s **" % package_name)
    try:
      invoke_swift(package_path=args.package_path,
        swift_exec=args.swift_exec,
        action='build',
        products=['swift-format'],
        build_path=args.build_path,
        multiroot_data_file=args.multiroot_data_file,
        configuration=args.configuration,
        env=env,
        verbose=args.verbose)
    except subprocess.CalledProcessError as e:
      printerr('FAIL: Building %s failed' % package_name)
      printerr('Executing: %s' % ' '.join(e.cmd))
      sys.exit(1)

  output_dir = os.path.realpath(os.path.join(args.build_path, args.configuration))

  if should_run_action("generate-xcodeproj", args.build_actions):
    print("** Generating Xcode project for %s **" % package_name)
    try:
      generate_xcodeproj(args.package_path,
        swift_exec=args.swift_exec,
        env=env,
        verbose=args.verbose)
    except subprocess.CalledProcessError as e:
      printerr('FAIL: Generating the Xcode project failed')
      printerr('Executing: %s' % ' '.join(e.cmd))
      sys.exit(1)

  if should_run_action("test", args.build_actions):
    print("** Testing %s **" % package_name)
    try:
      invoke_swift(package_path=args.package_path,
        swift_exec=args.swift_exec,
        action='test',
        products=['%sPackageTests' % package_name],
        build_path=args.build_path,
        multiroot_data_file=args.multiroot_data_file,
        configuration=args.configuration,
        env=env,
        verbose=args.verbose)
    except subprocess.CalledProcessError as e:
      printerr('FAIL: Testing %s failed' % package_name)
      printerr('Executing: %s' % ' '.join(e.cmd))
      sys.exit(1)

  if should_run_action("install", args.build_actions):
    print("** Installing %s **" % package_name)

    swiftpm_args = get_swiftpm_options(
      package_path=args.package_path,
      build_path=args.build_path, 
      multiroot_data_file=args.multiroot_data_file,
      configuration=args.configuration,
      verbose=args.verbose
    )
    cmd = [args.swift_exec, 'build', '--show-bin-path'] + swiftpm_args
    bin_path = check_output(cmd, env=env, capture_stderr=False, verbose=args.verbose).strip()
    
    for prefix in args.install_prefixes:
        cmd = ['rsync', '-a', os.path.join(bin_path, 'swift-format'), os.path.join(prefix, 'bin')]
        check_call(cmd, verbose=args.verbose)

def main(argv_prefix = []):
  args = parse_args(argv_prefix + sys.argv[1:])
  run(args)

if __name__ == '__main__':
  main()