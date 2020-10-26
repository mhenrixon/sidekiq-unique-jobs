# Quick Notes to Help with Debugging

## Reducing

One of the most important steps is reducing the code sample to a
minimal reproduction. For example, one thing I'm debugging right now
was reported as:

```ruby
a, b, c, d, e, f, g, h, i, j = 1, *[p1, p2, p3], *[p1, p2, p3], *[p4, p5, p6]
```

This original sample has 10 items on the left-hand-side (LHS) and 1 +
3 groups of 3 (calls) on the RHS + 3 arrays + 3 splats. That's a lot.

It's already been reported (perhaps incorrectly) that this has to do
with multiple splats on the RHS, so let's focus on that. At a minimum
the code can be reduced to 2 splats on the RHS and some
experimentation shows that it needs a non-splat item to fail:

```
_, _, _ = 1, *[2], *[3]
```

and some intuition further removed the arrays:

```
_, _, _ = 1, *2, *3
```

the difference is huge and will make a ton of difference when
debugging.

## Getting something to compare

```
% rake debug3 F=file.rb
```

TODO

## Comparing against ruby / ripper:

```
% rake cmp3 F=file.rb
```

This compiles the parser & lexer and then parses file.rb using both
ruby, ripper, and ruby_parser in debug modes. The output is munged to
be as uniform as possible and diffable. I'm using emacs'
`ediff-files3` to compare these files (via `rake cmp3`) all at once,
but regular `diff -u tmp/{ruby,rp}` will suffice for most tasks.

From there? Good luck. I'm currently trying to backtrack from rule
reductions to state change differences. I'd like to figure out a way
to go from this sort of diff to a reasonable test that checks state
changes but I don't have that set up at this point.
