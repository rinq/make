_INIT ?= codecov.yml .gitignore LICENSE.md CHANGELOG.md .github/CONTRIBUTING.md

.PHONY:
init:: $(_INIT)

$(_INIT):
	curl --create-dirs '-#Lo' "$@" "https://rinq.github.io/make/common/skel/$(@:.%=%)?nonce=$$(date +%s)"
