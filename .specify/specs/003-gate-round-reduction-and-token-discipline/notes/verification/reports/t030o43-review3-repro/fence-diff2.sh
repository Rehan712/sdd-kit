#!/usr/bin/env bash
K="$1"; . "$K/scripts/verification-lib.sh"
corpus="$TMPDIR/fence-corpus2.md"; : > "$corpus"
ws=($'\302\205' $'\302\240' $'\341\232\200' $'\342\200\200' $'\342\200\201' $'\342\200\202' $'\342\200\203' $'\342\200\204' $'\342\200\205' $'\342\200\206' $'\342\200\207' $'\342\200\210' $'\342\200\211' $'\342\200\212' $'\342\200\250' $'\342\200\251' $'\342\200\257' $'\342\201\237' $'\343\200\200')
tpl=('%s```' '```%s' '```text%s' '  %s```' '%s~~~' '~~~%s' '````%s' '%s> quote' '>%squote' '%s<!-- c' '<!--%s c' 'x %s<!-- c' 'c -->%s' '%s-->' '%s<pre>' '<pre%s>' '<pre>%s' '</pre%s>' '%s</pre>' '<pre%s' '<script%s>' '<?%s' '%s?>' '<!%sDOCTYPE' '<![CDATA[%s' ']]>%s' '`%s<!--%s`' '``%s<!--`%s``' '    %s```' '%s    ```' '<!--%sgate-round-end: opponent:1%s-->' 'plain %s text' ' %s ```' '```%s```' '%s```%s' '<!-- a -->%s<!-- b' '<pre>%s</pre>')
ctx=('' '```' '````' '~~~' '<!--' '<pre>' '<script>' '<?' '<!X' '<![CDATA[')
for c in "${ws[@]}"; do for t in "${tpl[@]}"; do for x in "${ctx[@]}"; do
  printf '@@RESET@@\n' >> "$corpus"; [[ -z "$x" ]] || printf '%s\n' "$x" >> "$corpus"
  printf "$t\n" "$c" "$c" >> "$corpus"; printf 'probe line\n' >> "$corpus"
done; done; done
prog='$0=="@@RESET@@" {fenced=0; commented=0; rawkind=0; vf_fence_ch=""; vf_fence_n=0; print "R"; next} { q = vf_quoted($0); printf "%d %d %d %s %s %s\n", q, fenced, commented, rawkind, vf_fence_ch, vf_fence_n }'
raw="$(awk "$_VF_AWK_FENCE$prog" "$corpus")"
map="$(awk "$_VF_AWK_WS$_VF_AWK_FENCE"'$0!="@@RESET@@" {$0 = vf_ws($0)}'"$prog" "$corpus")"
echo "lines=$(wc -l < "$corpus") samples=$(grep -c '@@RESET@@' "$corpus")"
if [[ "$raw" == "$map" ]]; then echo "SAME state sequence"; else echo "DIFFER"; diff <(echo "$raw") <(echo "$map") | head; fi
echo "quoted: $(echo "$raw" | awk '$1==1' | wc -l) unquoted: $(echo "$raw" | awk '$1==0' | wc -l)"
