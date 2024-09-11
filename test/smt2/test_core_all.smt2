(declare-const x Bool)
(declare-const y Bool)
(declare-const z Bool)
(declare-const w Bool)
(assert (distinct x false))
(assert
  (and
    (or (not x) y)
    (or (not y) z)))
(assert (or (not x) z))
(check-sat)
(assert (= w (ite (xor x z) true false)))
(assert (or (not (and x z)) (not w)))
(check-sat)
(get-model)