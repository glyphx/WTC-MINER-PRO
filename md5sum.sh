(
cd  && for f in *
do
  if [[  == *.md5 ]] ; then
      md5sum -c 
  fi
done
)
