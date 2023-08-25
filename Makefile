major:
	@git pull --tags; \
	IFS='.' read -ra tag <<< "$$(git tag | sed 's/v//gi' | sort -t "." -k1,1nr -k2,2nr -k3,3nr | head -1)"; \
	bump=$$(($${tag[0]} + 1)); \
	ver=v$$bump.0.0; \
	git tag $$ver; \
	echo "Made tag $$ver"; \
	echo "Do this to push it: git push origin $$ver"

minor:
	@git pull --tags; \
	IFS='.' read -ra tag <<< "$$(git tag | sed 's/v//gi' | sort -t "." -k1,1nr -k2,2nr -k3,3nr | head -1)"; \
	bump=$$(($${tag[1]} + 1)); \
	ver=v$${tag[0]}.$$bump.0; \
	git tag $$ver; \
	echo "Made tag $$ver"; \
	echo "Do this to push it: git push origin $$ver"

patch:
	@git pull --tags; \
	IFS='.' read -ra tag <<< "$$(git tag | sed 's/v//gi' | sort -t "." -k1,1nr -k2,2nr -k3,3nr | head -1)"; \
	bump=$$(($${tag[2]} + 1)); \
	ver=v$${tag[0]}.$${tag[1]}.$$bump; \
	git tag $$ver; \
	echo "Made tag $$ver"; \
	echo "Do this to push it: git push origin $$ver"

enterprise:
	@git pull --tags; \
	latest_tag=v"$$(git tag | sed 's/v//gi' | sort -t "." -k1,1nr -k2,2nr -k3,3nr | head -1)"; \
	enterprise_tag="$$latest_tag"-enterprise; \
	git tag $$enterprise_tag $$latest_tag; \
	echo "Made tag $$enterprise_tag"; \
	echo "Do this to push it: git push origin $$enterprise_tag"

release_major: major

release_minor: minor

release_patch: patch
