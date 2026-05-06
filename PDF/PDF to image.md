pkg install poppler

pdftocairo -jpeg "all_combined.pdf" page


Change the name of all_combined.pdf to work and also keep the pdf in trial folder 


For specific pages:

pdftocairo -jpeg -f 5 -l 5 "Edit.pdf" "page"

Put page no.s f for initial and l for final

