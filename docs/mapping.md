# Rulemak-CDH Mapping

## Adaptation Type

This layout uses a Colemak-DH/Codemak-DH adaptation of Rulemak.

The macOS input source maps Colemak-DH-style Latin positions to Rulemak Cyrillic output.

## Source Rulemak Mapping

```text
QWERTY q -> я
QWERTY w -> ж
QWERTY e -> ф
QWERTY r -> п
QWERTY t -> г
QWERTY y -> й
QWERTY u -> л
QWERTY i -> у
QWERTY o -> ы
QWERTY p -> ю
QWERTY [ -> ш
QWERTY ] -> щ

QWERTY a -> а
QWERTY s -> р
QWERTY d -> с
QWERTY f -> т
QWERTY g -> д
QWERTY h -> ч
QWERTY j -> н
QWERTY k -> е
QWERTY l -> и
QWERTY ; -> о
QWERTY ' -> ь
QWERTY ` -> ё
QWERTY \ -> э

QWERTY z -> з
QWERTY x -> х
QWERTY c -> ц
QWERTY v -> в
QWERTY b -> б
QWERTY n -> к
QWERTY m -> м
QWERTY = -> ъ
```

## Rulemak-CDH Table

```text
Q -> я
W -> ж
F -> ф
P -> п
B -> б

A -> а
R -> р
S -> с
T -> т
G -> г

Z -> з
X -> х
C -> ц
D -> д
V -> в

J -> й
L -> л
U -> у
Y -> ы
; -> ю

M -> м
N -> н
E -> е
I -> и
O -> о
' -> ь

K -> к
H -> ч

` -> ё
= -> ъ
\ -> э
[ -> ш
] -> щ
```

## macOS Control Keys

The layout explicitly defines:

```text
Return    key code 36
Tab       key code 48
Backspace key code 51
```

Backspace uses XML-valid `U+007F` rather than `U+0008`.

## macOS Shortcuts

Command shortcuts are routed through the Latin key map. This keeps common application shortcuts working while the layout is active.
