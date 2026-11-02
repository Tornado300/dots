;; extends

;; nvim-treesitter's bundled python folds.scm folds match_statement but not
;; case_clause, so only the top "match x:" line folds -- the individual
;; "case ...:" blocks don't. Add case_clause here.
(case_clause) @fold
