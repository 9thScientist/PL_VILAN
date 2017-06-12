vilan: vilan.y vilan.fl codeBuilder.c basicTypes.c
	yacc vilan.y
	flex vilan.fl
	cc codeBuilder.c basicTypes.c y.tab.c `pkg-config --cflags --libs glib-2.0` -o vilan

clean:
	rm y.tab.c lex.yy.c
