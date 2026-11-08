set -eu
printf 'BASH_VERSION=%s\n' "$BASH_VERSION" >&2
if [[ ${1:-default} != default ]]; then shopt -s patsub_replacement; [[ $1 != off ]] || shopt -u patsub_replacement; fi
shopt -p patsub_replacement >&2 || :
if [[ -r /etc/os-release ]]; then cat /etc/os-release >&2; fi
fixture_probe() {
  local weak_redirect_cases=() runner_redirect_cases=() redirect prefix tool spacing
  for tool in grep rg diff; do
    for prefix in '' /usr/bin/ ./tools/ tests/; do
      for redirect in '>|out.txt' ' >|out.txt' '>| out.txt' ' >| out.txt'; do
        weak_redirect_cases+=("$prefix$tool$redirect old new")
      done
    done
  done
  for redirect in '<input.txt' '>out.txt' '>>out.txt' '>|out.txt' '<>input.txt' '<&0' '>&1' '&>out.txt'; do
    for spacing in '' ' '; do
      for fixture in 'grepREDIRECT AC-001 README.md' 'rg AC-001REDIRECT README.md' \
        'diff oldREDIRECT new' 'tscREDIRECT --noEmit' 'npm runREDIRECT typecheck' \
        'npmREDIRECT run build' 'testREDIRECT -e README.md' 'test -fREDIRECT README.md'; do
        weak_redirect_cases+=("${fixture/REDIRECT/$spacing$redirect}")
      done
      for fixture in 'bashREDIRECT tests/typecheck.sh' 'nodeREDIRECT --test test/build.js' \
        'cargo testREDIRECT --test typecheck' 'python3 -mREDIRECT pytest tests/build.py' \
        'npm runREDIRECT test -- --grep typecheck' './tests/check-typecheck.shREDIRECT /usr/bin/grep'; do
        runner_redirect_cases+=("${fixture/REDIRECT/$spacing$redirect}")
      done
    done
  done

for fixture in "${weak_redirect_cases[@]}"; do printf 'generated_weak\0%s\0' "$fixture"; done
for fixture in "${runner_redirect_cases[@]}"; do printf 'generated_runner\0%s\0' "$fixture"; done
  for fixture in \
    'npm run build' 'npm run typecheck' 'tsc --noEmit' 'grep AC-001 README.md' \
    'tsc --noEmit tests/unit.ts' 'npm run typecheck -- --project tests/tsconfig.json' \
    'grep AC-001 tests/check.sh' 'npm run build -- --outDir tests/build' \
    'test -e README.md' 'test -f README.md' 'grep pytest README.md' \
    'rg bats README.md' 'diff fixtures/test.txt actual.txt' \
    'grep test README.md' 'grep tests README.md' 'grep "node --test" README.md' \
    'grep "cargo test" README.md' 'grep AC-001 scripts/test-check.sh' \
    'test -e tests/check.sh' 'test -f tests/check.sh' \
    'rg /usr/bin/pytest README.md' 'diff fixtures/bats.txt actual.txt' \
    'bash --rcfile tests/env.sh -c "npm run typecheck"' \
    '/usr/bin/grep AC-001 tests/check.sh' \
    '/usr/bin/grep<input.txt AC-001 tests/check.sh' '/usr/bin/grep <input.txt AC-001 tests/check.sh' \
    '/usr/bin/grep>output.txt AC-001 tests/check.sh' '/usr/bin/grep >output.txt AC-001 tests/check.sh' \
    '/usr/bin/rg AC-001 tests/check.sh' \
    '/usr/bin/rg<input.txt AC-001 tests/check.sh' '/usr/bin/rg <input.txt AC-001 tests/check.sh' \
    '/usr/bin/rg>output.txt AC-001 tests/check.sh' '/usr/bin/rg >output.txt AC-001 tests/check.sh' \
    '/usr/bin/diff fixtures/test.txt actual.txt' \
    '/usr/bin/diff<input.txt fixtures/test.txt actual.txt' '/usr/bin/diff <input.txt fixtures/test.txt actual.txt' \
    '/usr/bin/diff>output.txt fixtures/test.txt actual.txt' '/usr/bin/diff >output.txt fixtures/test.txt actual.txt' \
    './tools/grep AC-001 tests/check.sh' \
    './tools/grep<input.txt AC-001 tests/check.sh' './tools/grep <input.txt AC-001 tests/check.sh' \
    './tools/grep>output.txt AC-001 tests/check.sh' './tools/grep >output.txt AC-001 tests/check.sh' \
    './tools/rg AC-001 tests/check.sh' \
    './tools/rg<input.txt AC-001 tests/check.sh' './tools/rg <input.txt AC-001 tests/check.sh' \
    './tools/rg>output.txt AC-001 tests/check.sh' './tools/rg >output.txt AC-001 tests/check.sh' \
    './tools/diff fixtures/test.txt actual.txt' \
    './tools/diff<input.txt fixtures/test.txt actual.txt' './tools/diff <input.txt fixtures/test.txt actual.txt' \
    './tools/diff>output.txt fixtures/test.txt actual.txt' './tools/diff >output.txt fixtures/test.txt actual.txt' \
    'tools/grep AC-001 tests/check.sh' 'tools/rg AC-001 tests/check.sh' 'tools/diff fixtures/test.txt actual.txt' \
    '../tools/grep AC-001 tests/check.sh' '../tools/rg AC-001 tests/check.sh' '../tools/diff fixtures/test.txt actual.txt' \
    'tests/grep AC-001 tests/check.sh' 'tests/rg AC-001 tests/check.sh' 'tests/diff fixtures/test.txt actual.txt' \
    'npm<tests/test-typecheck.txt run typecheck' 'npm <tests/test-typecheck.txt run typecheck' \
    'tsc>tests/test-typecheck.log --noEmit' 'tsc >tests/test-typecheck.log --noEmit' \
    'grep<tools/pytest typecheck' 'grep <tools/pytest typecheck' \
    'grep<tools/npm test typecheck.txt' 'grep <tools/npm test typecheck.txt' \
    'npm<tests/check.txt run typecheck' 'npm <tests/check.txt run typecheck' \
    'npm>tests/check.txt run typecheck' 'npm >tests/check.txt run typecheck' \
    'npm<tests/check.txt run build' 'npm <tests/check.txt run build' \
    'npm>tests/check.txt run build' 'npm >tests/check.txt run build' \
    'tsc<input.txt --noEmit' 'tsc <input.txt --noEmit' \
    'tsc>input.txt --noEmit' 'tsc >input.txt --noEmit' \
    'grep<input.txt AC-001 README.md' 'grep <input.txt AC-001 README.md' \
    'grep>input.txt AC-001 README.md' 'grep >input.txt AC-001 README.md' \
    'rg<tools/pytest AC-001 README.md' 'rg <tools/pytest AC-001 README.md' \
    'rg>tools/pytest AC-001 README.md' 'rg >tools/pytest AC-001 README.md' \
    'diff<tools/bats actual.txt expected.txt' 'diff <tools/bats actual.txt expected.txt' \
    'diff>tools/bats actual.txt expected.txt' 'diff >tools/bats actual.txt expected.txt' \
    'test<tests/check.txt -e README.md' 'test <tests/check.txt -e README.md' \
    'test>tests/check.txt -e README.md' 'test >tests/check.txt -e README.md' \
    'grep<tools/bash tests/typecheck.sh' 'grep <tools/bash tests/typecheck.sh' \
    'grep>tools/bash tests/typecheck.sh' 'grep >tools/bash tests/typecheck.sh' \
    'grep<tests/check.sh typecheck.txt' 'grep <tests/check.sh typecheck.txt' \
    'grep>tests/check.sh typecheck.txt' 'grep >tests/check.sh typecheck.txt' \
    'tsc 2>output.txt --noEmit' 'npm2>output.txt test typecheck.txt' \
    'npm&>tests/typecheck.log run build' 'tsc>&tests/check.log --noEmit' \
    'npm 2&>out.txt test typecheck.txt' \
    "${weak_redirect_cases[@]}"; do printf 'weak\0%s\0' "$fixture"; done
  for fixture in \
    'bash tests/check.sh' 'sh tests/check.sh' './tests/check.sh' \
    'bash -e tests/typecheck.sh' '/bin/bash tests/typecheck.sh' './scripts/test-build.sh' \
    'node --test test/typecheck.test.js' 'cargo test --test build' \
    'pytest tests/typecheck.py' '/usr/bin/pytest tests/typecheck.py' 'bats tests/build.bats' \
    'python3 -m pytest tests/typecheck.py' \
    'npm test -- --grep typecheck' 'npm run test -- --grep typecheck' \
    '/usr/local/bin/npm test -- --grep typecheck' 'pnpm test --filter typecheck' \
    'yarn run test --grep typecheck' 'make test TARGET=typecheck' \
    'bun test tests/typecheck.test.ts' 'go test ./typecheck' \
    'bash<input.txt tests/typecheck.sh' 'bash <input.txt tests/typecheck.sh' \
    'bash>input.txt tests/typecheck.sh' 'bash >input.txt tests/typecheck.sh' \
    './tests/check-typecheck.sh<input.txt' './tests/check-typecheck.sh <input.txt' \
    './tests/check-typecheck.sh>input.txt' './tests/check-typecheck.sh >input.txt' \
    'node<input.txt --test test/typecheck.test.js' 'node <input.txt --test test/typecheck.test.js' \
    'node>input.txt --test test/typecheck.test.js' 'node >input.txt --test test/typecheck.test.js' \
    'cargo<input.txt test --test typecheck' 'cargo <input.txt test --test typecheck' \
    'cargo>input.txt test --test typecheck' 'cargo >input.txt test --test typecheck' \
    'pytest<input.txt tests/typecheck.py' 'pytest <input.txt tests/typecheck.py' \
    'pytest>input.txt tests/typecheck.py' 'pytest >input.txt tests/typecheck.py' \
    '/usr/bin/python3<input.txt -m pytest tests/typecheck.py' '/usr/bin/python3 <input.txt -m pytest tests/typecheck.py' \
    '/usr/bin/python3>input.txt -m pytest tests/typecheck.py' '/usr/bin/python3 >input.txt -m pytest tests/typecheck.py' \
    'npm<input.txt run test -- --grep typecheck' 'npm <input.txt run test -- --grep typecheck' \
    'npm>input.txt run test -- --grep typecheck' 'npm >input.txt run test -- --grep typecheck' \
    'npm 2>output.txt run test -- --grep typecheck' 'bash 0<input.txt -e tests/typecheck.sh' \
    '/bin/bash tests/check.sh /usr/bin/grep' './tests/check.sh ./tools/rg' \
    '/usr/bin/node --test test/check.js ../tools/diff' \
    'node scripts/assert-content.js /usr/bin/grep AC-001 README.md' \
    'node scripts/assert-content.js ./tools/rg AC-001 README.md' \
    'node scripts/assert-content.js ../tools/diff actual.txt expected.txt' \
    'bash&>tests/build.log tests/typecheck.sh' 'npm>&tests/typecheck.log run test' \
    'node>|tests/build.log --test test/typecheck.js' 'pytest<>tests/build.txt tests/typecheck.py' \
    'bats&>out.txt tests/build.bats' 'pnpm>|out.txt test --filter typecheck' \
    'yarn run>|out.txt test --grep typecheck' 'bun>|out.txt test tests/build.ts' \
    'go test>|out.txt ./typecheck' 'make>|out.txt test TARGET=typecheck' \
    "${runner_redirect_cases[@]}"; do printf 'runner\0%s\0' "$fixture"; done
}
fixture_probe
