vilan: vilan.y vilan.fl codeBuilder.c basicTypes.c
	yacc vilan.y
	flex vilan.fl
	cc -g y.tab.c codeBuilder.c basicTypes.c `pkg-config --cflags --libs glib-2.0` -o vilan

clean:
	rm y.tab.c lex.yy.c
