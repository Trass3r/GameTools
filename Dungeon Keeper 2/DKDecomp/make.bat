dmc -c decomp.c
dmd -ofDKDecomp main.d compression.d decomp.obj -release -O -inline
pause