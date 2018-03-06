all: Makefile.coq
	+make -f Makefile.coq all

clean: Makefile.coq
	+make -f Makefile.coq clean
	rm -f Makefile.coq Makefile.coq.conf

Make:;

Makefile.coq: Make
	$(COQBIN)coq_makefile -f Make -o Makefile.coq

%: Makefile.coq
	+make -f Makefile.coq $@

.PHONY: all clean
