MIN_COVERAGE=`cat min.coverage`

function test() {
forge test --ast -vvv \
	&& rm -rf coverage \
	&& mkdir coverage \
	&& npm run gen-coverage
}

if ! test; then
	exit 1
fi


if ! lcov --summary coverage/lcov.info --fail-under-lines $MIN_COVERAGE --quiet; then
	echo -e "\033[0;31mCurrent Code test coverage is less than $MIN_COVERAGE%. Please consider increasing it\033[0m"
	npm run open-coverage
	exit 1
fi