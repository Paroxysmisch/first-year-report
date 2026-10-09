// first-year-report: a clean, professional Typst template for PhD
// first-year / annual reports.
//
// Usage (see template/main.typ for a full worked example):
//
//   #import "@local/first-year-report:0.1.0": report, callout
//
//   #show: report.with(
//     title: "Your Report Title",
//     author: "Your Name",
//     ...
//   )
//
//   = Introduction
//   ...

/// A tinted, left-bordered admonition box for notes, open questions, or
/// discussion points to raise with a supervisor.
#let callout(title: "Note", color: rgb("#C98A2B"), body) = {
  block(
    width: 100%,
    fill: color.lighten(90%),
    stroke: (left: 2pt + color),
    inset: (left: 12pt, rest: 10pt),
    radius: 2pt,
    breakable: true,
    above: 1.2em,
    below: 1.2em,
    [
      #text(weight: "bold", fill: color.darken(25%))[#title]
      #linebreak()
      #body
    ],
  )
}

/// A compact numbered list, styled like the big bold numerals in the table
/// of contents but a good deal smaller — handy for outlining a short list
/// of research directions, options, or steps inline in the body text.
/// Each positional argument is one item's content, e.g.
/// `#directions[*Direction one.* ...][*Direction two.* ...]`.
#let directions(
  primary-color: rgb("#1B2A4A"),
  heading-font: "New Computer Modern",
  ..items,
) = {
  v(2em, weak: true)
  for (i, item) in items.pos().enumerate() {
    grid(
      columns: (1.8em, 1fr),
      column-gutter: 10pt,
      align: (left + top, left + top),
      text(weight: "bold", fill: primary-color, font: heading-font)[#(i + 1)],
      item,
    )
    v(2em, weak: true)
  }
}

/// The main template function. Wrap your document body with
/// `#show: report.with(...)`.
#let report(
  // --- content / metadata ---
  title: "Report Title",
  subtitle: none,
  author: "Author Name",
  student-id: none,
  department: "Department Name",
  institution: "Institution Name",
  degree: "Doctor of Philosophy",
  report-type: "First Year Report",
  supervisor: none,
  advisor: none,
  logo: none,
  logo-width: 1.6cm,
  date: datetime.today(),
  abstract: none,
  abbreviations: none,
  abbreviations-title: "List of Abbreviations",
  bibliography-file: none,
  bibliography-style: "apa",
  // --- look and feel (override any of these at use-time) ---
  primary-color: rgb("#1B2A4A"),
  accent-color: rgb("#C98A2B"),
  body-font: "New Computer Modern",
  heading-font: "New Computer Modern",
  mono-font: "DejaVu Sans Mono",
  chapter-label: "Chapter",
  font-size: 12pt,
  paper: "a4",
  doc,
) = {
  let ink = rgb("#111111")
  let muted = rgb("#8A8A8A")
  let hairline = rgb("#E4E4E4")

  // ---------------------------------------------------------------------
  // Document metadata
  // ---------------------------------------------------------------------
  set document(title: title, author: author)

  // ---------------------------------------------------------------------
  // Base typography
  // ---------------------------------------------------------------------
  set text(font: body-font, size: font-size, lang: "en", fill: ink)
  set par(justify: true, leading: 0.65em, spacing: 1.15em, first-line-indent: 0pt)
  set heading(numbering: "1.1")

  // Chapter opening: a big italic title, with a small-caps italic
  // "Chapter N" label set tight underneath it — quiet and literary rather
  // than numeral-heavy.
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    v(10pt)
    text(size: 25pt, weight: "regular", style: "italic", fill: ink, font: heading-font)[#it.body]
    if it.numbering != none {
      linebreak()
      smallcaps(text(size: 12.5pt, weight: "regular", style: "italic", fill: primary-color)[
        #chapter-label #counter(heading).display(it.numbering)
      ])
    }
    v(22pt)
  }

  // Section heading: italic numeral (a touch smaller than the title, as in
  // the reference) + title, followed by a rule that fills the rest of the
  // line out to the margin.
  show heading.where(level: 2): it => block(above: 1.6em, below: 0.9em)[
    #grid(
      columns: (auto, 1fr),
      column-gutter: 10pt,
      align: (left + horizon, left + horizon),
      [
        #if it.numbering != none [
          #text(size: 12pt, weight: "regular", style: "italic", fill: ink, font: heading-font)[#counter(heading).display(it.numbering)#"."]
          #h(6pt)
        ]
        #text(size: 15pt, weight: "regular", style: "italic", fill: ink, font: heading-font)[#it.body]
      ],
      line(length: 100%, stroke: 0.6pt + ink),
    )
  ]

  show heading.where(level: 3): it => block(above: 1.4em, below: 0.9em)[
    #text(size: 1em, weight: "regular", style: "italic", fill: primary-color, font: heading-font)[#it.body]
  ]

  // ---------------------------------------------------------------------
  // Links
  // ---------------------------------------------------------------------
  show link: it => text(fill: accent-color, it)

  // ---------------------------------------------------------------------
  // Code blocks
  // ---------------------------------------------------------------------
  show raw.where(block: true): it => block(
    width: 100%,
    fill: rgb("#F6F6F6"),
    stroke: (left: 2pt + accent-color),
    inset: 10pt,
    radius: 2pt,
    above: 1.2em,
    below: 1.2em,
    text(font: mono-font, size: 9.5pt, it),
  )
  show raw.where(block: false): it => box(
    fill: rgb("#EFEFEF"),
    inset: (x: 3pt, y: 0pt),
    outset: (y: 2pt),
    radius: 2pt,
    text(font: mono-font, it),
  )

  // ---------------------------------------------------------------------
  // Figures & tables
  // ---------------------------------------------------------------------
  show figure.caption: it => text(size: 9.5pt)[
    #text(weight: "bold", fill: accent-color)[
      #it.supplement #context it.counter.display(it.numbering)#it.separator
    ]
    #it.body
  ]

  // A quiet, "booktabs"-style table: bold header, one primary-color rule
  // under it, faint hairlines between rows, no fills.
  set table(
    stroke: (x, y) => if y == 0 { (bottom: 1pt + primary-color) } else { (bottom: 0.6pt + hairline) },
    inset: (x: 8pt, y: 7pt),
  )
  show table.cell.where(y: 0): set text(weight: "bold")

  // ---------------------------------------------------------------------
  // Page setup: front matter (roman numerals, no running header)
  // ---------------------------------------------------------------------
  set page(
    paper: paper,
    margin: (x: 2.75cm, top: 3cm, bottom: 3cm),
    numbering: "i",
    footer: context {
      if counter(page).get().first() > 1 {
        align(center, text(size: 9pt, fill: muted)[#counter(page).display("i")])
      }
    },
  )
  counter(page).update(1)

  // ---------------------------------------------------------------------
  // Cover page — left-aligned, minimal: a big title, the author as the
  // prominent named figure right beneath it, supervisor/advisor kept
  // secondary through a quiet label + regular (non-bold) weight rather
  // than through tiny type, and the institution/logo tucked away at the
  // very bottom.
  // ---------------------------------------------------------------------
  let title-len = if type(title) == str { title.len() } else { 60 }
  let title-size = if title-len > 90 { 22pt } else if title-len > 55 { 27pt } else { 33pt }

  v(1fr)
  text(size: title-size, weight: "bold", fill: ink, font: heading-font)[#title]
  if subtitle != none {
    v(10pt)
    text(size: 13pt, style: "italic", fill: rgb("#555555"))[#subtitle]
  }
  v(18pt)
  line(length: 100%, stroke: 0.6pt + primary-color)
  v(20pt)
  text(size: 19pt, weight: "bold", fill: ink)[#author]
  v(24pt)
  if supervisor != none {
    text(size: 9pt, tracking: 1.5pt, fill: accent-color)[SUPERVISOR]
    linebreak()
    text(size: 13pt, style: "italic", fill: rgb("#333333"))[#supervisor]
    v(12pt)
  }
  if advisor != none {
    text(size: 9pt, tracking: 1.5pt, fill: accent-color)[ADVISOR]
    linebreak()
    text(size: 13pt, style: "italic", fill: rgb("#333333"))[#advisor]
  }
  v(1fr)
  grid(
    columns: (auto, 1fr),
    column-gutter: 20pt,
    align: horizon,
    if logo != none { image(logo, width: logo-width) } else { [] },
    text(size: 10pt, fill: muted)[
      // #institution#if department != none [, #department]
      #report-type submitted in partial fulfilment of the requirements for the degree of #degree
      (#date.display("[month repr:long] [year]"))
    ],
  )

  // ---------------------------------------------------------------------
  // Abstract — vertically centered on its own page, narrower ICLR-style
  // margins.
  // ---------------------------------------------------------------------
  if abstract != none {
    pagebreak()
    v(1fr)
    pad(x: 1.4cm)[
      #text(size: 25pt, weight: "regular", style: "italic", fill: ink, font: heading-font)[Abstract]
      #v(22pt)
      #text(size: 10.5pt)[#abstract]
    ]
    v(1.3fr)
  }

  // ---------------------------------------------------------------------
  // List of abbreviations — same treatment as the abstract page (vertically
  // centered, narrow margins, italic title), just with different content.
  // Pass e.g. `abbreviations: abbr.list()` from the `@preview/abbr` package.
  // ---------------------------------------------------------------------
  if abbreviations != none {
    pagebreak()
    v(1fr)
    pad(x: 1.4cm)[
      #text(size: 25pt, weight: "regular", style: "italic", fill: ink, font: heading-font)[#abbreviations-title]
      #v(22pt)
      // Some glossary packages (e.g. `abbr.list()`) emit their own
      // level-1 heading for a title — neutralize it here so it doesn't
      // duplicate the one above or trigger our chapter-opening treatment
      // (pagebreak, numbering) while nested inside this container.
      #show heading.where(level: 1): it => it.body
      #text(size: 10.5pt)[#abbreviations]
    ]
    v(1.3fr)
  }

  // ---------------------------------------------------------------------
  // Table of contents — an editorial index: big bold chapter numerals
  // (echoed later at each chapter opening), smaller indented subsections,
  // and a hairline between chapter groups. Built by hand from a heading
  // query rather than plain `outline()` so the numerals can be this big.
  // ---------------------------------------------------------------------
  pagebreak()
  text(size: 25pt, weight: "regular", style: "italic", fill: ink, font: heading-font)[Table of Contents]
  v(28pt)

  context {
    let heads = query(heading.where(outlined: true))
    let first = true
    for h in heads {
      if h.level == 1 {
        if not first {
          v(16pt)
          line(length: 100%, stroke: 0.5pt + hairline)
          v(16pt)
        }
        first = false
        link(h.location(), grid(
          columns: (2.4em, 1fr, auto),
          column-gutter: 14pt,
          align: (left + horizon, left + horizon, right + horizon),
          if h.numbering != none {
            text(size: 22pt, weight: "bold", fill: primary-color, font: heading-font)[
              #numbering(h.numbering, ..counter(heading).at(h.location()))
            ]
          },
          text(size: 13pt, weight: "bold", fill: ink)[#h.body],
          text(size: 11pt, fill: muted)[#counter(page).at(h.location()).at(0)],
        ))
      } else if h.level == 2 {
        v(7pt)
        link(h.location(), grid(
          columns: (2.4em, 1fr, auto),
          column-gutter: 14pt,
          [],
          text(size: 10.5pt, fill: rgb("#444444"))[#h.body],
          text(size: 10pt, fill: muted)[#counter(page).at(h.location()).at(0)],
        ))
      }
    }
  }

  // ---------------------------------------------------------------------
  // Main matter: arabic numerals, running chapter header
  // ---------------------------------------------------------------------
  set page(
    numbering: "1",
    header: context {
      // No running header on a chapter's opening page — the big chapter
      // title already says what it is, and showing the *previous*
      // chapter's name there (the only one known at the top of the page)
      // would just be confusing.
      let opens-chapter = query(heading.where(level: 1)).any(h => h.location().page() == here().page())
      if not opens-chapter {
        let past = query(heading.where(level: 1).before(here()))
        if past.len() > 0 {
          align(right, text(size: 8.5pt, fill: muted, tracking: 0.6pt)[#upper(past.last().body)])
        }
      }
    },
    footer: context align(center, text(size: 9pt, fill: muted)[#counter(page).display("1")]),
  )
  counter(page).update(1)

  doc

  // ---------------------------------------------------------------------
  // Bibliography
  // ---------------------------------------------------------------------
  if bibliography-file != none {
    show bibliography: set text(size: 10pt)
    bibliography(bibliography-file, style: bibliography-style, title: [References])
  }
}
