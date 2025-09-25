#include:amsmath
#include:mathtools
#include:physics
#include:thmtools
#include:tikz
#include:tcolorbox
#include:hyperref
#include:babel
#include:xeCJK
#include:geometry
#include:xcolor
#include:listings
#include:enumitem
#include:graphicx
#include:newfloat
#include:float

# Then your package's own include
#include:tedpreamble

# Then your \usepackage line
\usepackage[options]{tedpreamble}#u

#keyvals:\usepackage/tedpreamble
options%keyvals#c
 paper, top##L, bottom##L, left##L, right##L, headheight##L, linespread,
 languages%text,
 draft=#true,false,
 defaultfonts=#true,false,
 notomathscale,
 mainfont%text, mainfontbold%text, mainfontitalic%text,
 sansfont%text, sansfontbold%text, sansfontitalic%text,
 monofont%text,
 cjkmain%file, cjksans%file, cjkmono%text,
 hidelinks=#true,false,
 linkcolor#%color, urlcolor#%color,
 docversion%text
#endkeyvals

# ---------------------------------------
# Public user commands
# ---------------------------------------
\version{version%text}
\email{email%text}
\makeopening[options]   # has only an optional keyval argument
\tcbnonumber

# Keyvals for \makeopening[...]
# ---------------------------------------
#keyvals:\makeopening
 email=#true,false,
 ver=#en,zh,both,none,
 time=#en,zh,both,none
#endkeyvals

# Unnumbered section helpers
\sectionnonumber{title%title}
\subsectionnonumber{title%title}
\subsubsectionnonumber{title%title}

# Theorem shorthands (wrapper commands)
\definition{text%text}
\theorem{text%text}
\lemma{text%text}
\corollary{text%text}
\proposition{text%text}

# ---------------------------------------
# Environments provided/defined by the package
# (TeXstudio picks up begin/end pairs from CWL.
# Use [title] optional like standard theorem-like envs.)
# ---------------------------------------

# Float environment "Graf" (from newfloat)
\begin{Graf}[placement]
\end{Graf}

# Proof environment
\begin{proof}
\end{proof}

\begin{ch_proof}
\end{ch_proof}

# tcolorbox-based environments
\begin{problem}[title%title]
\end{problem}
\begin{sporgsmal}[title%title]
\end{sporgsmal}

# Theorem-like environments (English)
\begin{theorem}[title%title]
\end{theorem}
\begin{lemma}[title%title]
\end{lemma}
\begin{corollary}[title%title]
\end{corollary}
\begin{observation}[title%title]
\end{observation}
\begin{definition}[title%title]
\end{definition}
\begin{example}[title%title]
\end{example}
\begin{notation}
\end{notation}
\begin{notation*}
\end{notation*}
\begin{corrections}
\end{corrections}
\begin{remark}
\end{remark}
\begin{proposition}[title%title]
\end{proposition}

\begin{theorem}
\end{theorem}
\begin{lemma}
\end{lemma}
\begin{corollary}
\end{corollary}
\begin{observation}
\end{observation}
\begin{definition}
\end{definition}
\begin{example}
\end{example}
\begin{proposition}
\end{proposition}

# Theorem-like environments (中文)
\begin{ch_theorem}[title%title]
\end{ch_theorem}
\begin{ch_lemma}[title%title]
\end{ch_lemma}
\begin{ch_corollary}[title%title]
\end{ch_corollary}
\begin{ch_observation}[title%title]
\end{ch_observation}
\begin{ch_definition}[title%title]
\end{ch_definition}
\begin{ch_example}[title%title]
\end{ch_example}
\begin{ch_notation}
\end{ch_notation}
\begin{ch_notation*}
\end{ch_notation*}
\begin{ch_corrections}
\end{ch_corrections}
\begin{ch_remark}
\end{ch_remark}

# Theorem-like environments (Dansk)
\begin{da_theorem}[title%title]
\end{da_theorem}
\begin{da_lemma}[title%title]
\end{da_lemma}
\begin{da_corollary}[title%title]
\end{da_corollary}
\begin{da_observation}[title%title]
\end{da_observation}
\begin{da_definition}[title%title]
\end{da_definition}
\begin{da_example}[title%title]
\end{da_example}
\begin{da_notation}
\end{da_notation}
\begin{da_notation*}
\end{da_notation*}
\begin{da_corrections}
\end{da_corrections}
\begin{da_remark}
\end{da_remark}

# ---------------------------------------
# Math helpers (mark as math-only where appropriate)
# ---------------------------------------
\N#m
\Z#m
\Q#m
\R#m
\C#m
\F#m
\E#m
\func{map%cmd}{domain%text}{codomain%text}
\og
\qog
\qeller
\qforalle
\tqc
\bimplies#m

# Pride flag helpers
\mtfrule{width%l}{height%l}
\mtfflag

# ---------------------------------------
# Nice-to-have: hyperlinks may appear when email is present,
# but \email's argument is plain text here.
# ---------------------------------------
