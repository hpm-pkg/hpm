#!/bin/sh

echo '#line 4 "'"$0"'"
#define T_CALLFN(id) \
    static int t_call_##id()
#define T_CALL(id,call) \
    T_CALLFN(id) { return call; }'

fn_ary="#line 11 \"$0\"
extern int (*fnames)()[] = {"

id=0
for fil in $@; do
  lno=0
  suite=$(expr "$fil" : '\(.*\)\.suite')
  tst=$(expr "$fil" : '.*\.suite/\(.*\)\.test\.sh')
  while read -r line; do
    ((lno=lno+1))

    if [ "${line:0:2}" = '##' ]; then
      echo "#line $lno \"$fil\"
#${line:2}"
    elif [ "${line:0:2}" = '#=' ]; then
      fnid="${suite}__${tst}__${id}"
      ((id=id+1))
      echo "#line 28 \"$0\"
T_CALL($fnid,
#line $lno \"$fil\"
${line:2}
#line 32 \"$0\"
)"
      fn_ary="$fn_ary
#line 35 \"$0\"
    t_call_$fnid,"
    elif [ "${line:0:2}" = '#{' ]; then
      fnid="${suite}__${tst}__${id}"
      ((id=id+1))
      echo "#line 40 \"$0\"
T_CALLFN($fnid)
#line $lno \"$fil\"
{"
      fn_ary="$fn_ary
#line 45 \"$0\"
    t_call_$fnid,"

      echo "$line" >>"$suite.suite/$tst.sh"
      while read -r ln; do
        ((lno=lno+1))
        echo "${ln:1}"
        echo "$ln" >>"$suite.suite/$tst.sh"
        if [ "${ln:0:2}" = '#}' ]; then
          break
        fi
      done
      continue
    fi

    if [ "$(expr "$line" : 't eval @@')" -ne 0 ]; then
      previd=$((id-1))
      echo "${line/t eval @@/t eval $previd}" >>"$suite.suite/$tst.sh"
    else
      echo "$line" >>"$suite.suite/$tst.sh"
    fi
    chmod +x "$suite.suite/$tst.sh"
  done <$fil
done

echo "$fn_ary
#line 69 \"$0\"
}"