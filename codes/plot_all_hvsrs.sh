#!/bin/bash
# GMT shell script for plotting csv output of make_hvsr.R
# Chris Van Houtte 2015
# Tested on GMTv5.4.2, requires pdfcrop.
for input in *.csv
do
out="${input%%d*}.ps"
outpdf="${input%%d*}.pdf"
gmtset FONT_LABEL 14p,Helvetica
gmtset FONT_ANNOT_PRIMARY 12p,Helvetica
maxn=`cut -f5 -d"," $input | sort -n | tail -1`
maxnp1=$(($maxn+1))
makecpt -Chot -T0/$maxnp1/0.1 -I > nrecs.cpt
psbasemap -R0.1/10/0.1/20 -JX8cl/5.6cl -B1f3:"Frequency (Hz)":/1f3:"H/V spectral ratio":/WeSn -X4 -Y10 -K > $out
psxy -JX -R -O -K -W1,220/220/220 -G220/220/220 <<END>> $out
0.102 0.5
0.102 2
9.8 2
9.8 0.5
END
awk -F',' '{if ((NR>1) && ($5>3)) print $1,$2,$4,$2,$2,$3}' $input | psxy -R -JX -Sc0.15c -W0.1,black -EY2p -O -K >> $out
awk -F',' '{if (NR>1) print $1,$2,$5}' $input | psxy -R -JX -Sc0.15c -W0.1,black -Cnrecs.cpt -O -K >> $out
echo 0.11 0.15 15 0 0 5 "${input%%d*}" | pstext -R -JX -K -N -O >> $out
psscale -Cnrecs.cpt -D0/0/5/0.15 -B"$maxnp1"f1:"Number of events": -O -X8.6c -Y2.8 -K >> $out
ps2pdf $out
pdfcrop -margins 10 $outpdf $outpdf
rm $out nrecs.cpt gmt.conf gmt.history
done
