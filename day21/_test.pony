use "ponytest"
use "collections"
use "regex"
use "debug"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

fun tag tests(test: PonyTest) =>
  test(_TestParse)
  test(_TestApply)
  test(_TestPuzzle)
  test(_TestUndo)
  test(_TestPuzzle2)

class SwapPosition
  let x: USize
  let y: USize
  new create(x': USize, y': USize) =>
    x = x'
    y = y'
  fun apply(s: String): String =>
    try
      let r = s.clone()
      r(x) = s(y)
      r(y) = s(x)
      r
    else
      Debug.err("** SP")
      s
    end
  fun undo(s: String): String =>
    apply(s)
  fun string(): String => "swap position"

class SwapLetter
  let x: U8
  let y: U8
  new create(x': U8, y': U8) =>
    x = x'
    y = y'
  fun apply(s: String): String =>
    try
      let r = s.clone()
      for i in Range(0, s.size()) do
        match s(i)
        | x => r(i) = y
        | y => r(i) = x
        end
      end
      r
    else
      Debug.err("** SL")
      s
    end
  fun undo(s: String): String =>
    apply(s)
  fun string(): String => "swap letter"

class RotateLeft
  let steps: USize
  new create(steps': USize) =>
    steps = steps'
  fun apply(s: String): String =>
    try
      let r = s.clone()
      for i in Range(0, s.size()) do
        r(i) = s( (i + steps) % s.size() )
      end
      r
    else
      Debug.err("** RL")
      s
    end
  fun undo(s: String): String =>
    RotateRight(steps).apply(s)
  fun string(): String => "rotate left"

class RotateRight
  let steps: USize
  new create(steps': USize) =>
    steps = steps'
  fun apply(s: String): String =>
    try
      let r = s.clone()
      for i in Range(0, s.size()) do
        r( (i + steps) % s.size() ) = s(i)
      end
      r
    else
      Debug.err("** RR")
      s
    end
  fun undo(s: String): String =>
    RotateLeft(steps).apply(s)
  fun string(): String => "rotate right"

class RotateBasedOnLetter
  let letter: U8
  new create(letter': U8) =>
    letter = letter'
  fun apply(s: String): String =>
    try
      var off: USize = 0
      var found = false
      for i in Range(0, s.size()) do
        if letter == s(i) then
          off = i
          found = true
          break
        end
      end
      if not found then
        Debug.err("Not found: " + letter.string())
      end
      if off >= 4 then
        off = off + 1
      end
      off = off + 1
      RotateRight(off).apply(s)
    else
      Debug.err("** RB")
      s
    end
  fun undo(s: String): String =>
    try
      var off: USize = 0
      var found = false
      for i in Range(0, s.size()) do
        if letter == s(i) then
          off = i
          found = true
          break
        end
      end
      if not found then
        Debug.err("Not found: " + letter.string())
      end
      off = match off
      | 1 => 1
      | 3 => 2
      | 5 => 3
      | 7 => 4
      | 2 => 6
      | 4 => 7
      | 6 => 8
      | 0 => 9
      else
        error
      end
      RotateLeft(off).apply(s)
    else
      Debug.err("** RB")
      s
    end
  fun string(): String => "rotate letter"

class ReversePositions
  let x: USize
  let y: USize
  new create(x': USize, y': USize) =>
    x = x'
    y = y'
  fun apply(s: String): String =>
    try
      let r = s.clone()
      for i in Range(x, y + 1) do
        let j = x + (y - i)
        r(j) = s(i)
      end
      r
    else
      Debug.err("** RP")
      s
    end
  fun undo(s: String): String =>
    apply(s)
  fun string(): String => "reverse position " + x.string() + " " + y.string()

class MovePosition
  let x: USize
  let y: USize
  new create(x': USize, y': USize) =>
    x = x'
    y = y'
  fun apply(s: String): String =>
    try
      let r = s.clone()
      r.delete(x.isize())
      r.insert_byte(y.isize(), s(x))
      r
    else
      Debug.err("** MP")
      s
    end
  fun undo(s: String): String =>
    try
      let r = s.clone()
      r.delete(y.isize())
      r.insert_byte(x.isize(), s(y))
      r
    else
      Debug.err("** MP")
      s
    end
  fun string(): String => "move position"

type Operation is (SwapPosition|SwapLetter
  |RotateLeft|RotateRight|RotateBasedOnLetter
  |ReversePositions|MovePosition
  )

class Scrambler
  var pass: String
  new create(pass': String) =>
    pass = pass'

  fun ref apply(op: Operation): String =>
    pass = op.apply(pass)
    pass

  fun ref undo(op: Operation): String =>
    pass = op.undo(pass)
    pass

  fun parse(lines: Array[String]): Array[Operation] ? =>
    let result = Array[Operation]
    for line in lines.values() do
      result.push(parseLine(line))
    end
    result

  fun parseLine(line: String): Operation ? =>
    let sp = Regex("swap position (\\d+) with position (\\d+)")
    let sl = Regex("swap letter (.) with letter (.)")
    let rl = Regex("rotate left (\\d+) steps?")
    let rr = Regex("rotate right (\\d+) steps?")
    let rb = Regex("rotate based on position of letter (.)")
    let rp = Regex("reverse positions (\\d+) through (\\d+)")
    let mp = Regex("move position (\\d+) to position (\\d+)")

    if sp == line then
      let matched = sp(line)
      return SwapPosition(
        matched(1).read_int[USize]()._1,
        matched(2).read_int[USize]()._1
      )
    end
    if sl == line then
      let matched = sl(line)
      return SwapLetter(
        matched(1)(0),
        matched(2)(0)
      )
    end
    if rl == line then
      let matched = rl(line)
      return RotateLeft(matched(1).read_int[USize]()._1)
    end
    if rr == line then
      let matched = rr(line)
      return RotateRight(matched(1).read_int[USize]()._1)
    end
    if rb == line then
      let matched = rb(line)
      return RotateBasedOnLetter(matched(1)(0))
    end
    if rp == line then
      let matched = rp(line)
      return ReversePositions(
        matched(1).read_int[USize]()._1,
        matched(2).read_int[USize]()._1
      )
    end
    if mp == line then
      let matched = mp(line)
      return MovePosition(
        matched(1).read_int[USize]()._1,
        matched(2).read_int[USize]()._1
      )
    end
    Debug.err("Unparsed line: [" + line + "]")
    error

class iso _TestParse is UnitTest
  fun name(): String => "parse"
  fun apply(h: TestHelper) =>
    let s: Scrambler ref = Scrambler("".clone())
    try
      let ops = s.parse(INPUT.sample().split("\n"))
      h.assert_eq[USize](4, (ops(0) as SwapPosition).x)
      h.assert_eq[USize](0, (ops(0) as SwapPosition).y)
      h.assert_eq[U8]('d', (ops(1) as SwapLetter).x)
      h.assert_eq[U8]('b', (ops(1) as SwapLetter).y)
      h.assert_eq[USize](0, (ops(2) as ReversePositions).x)
      h.assert_eq[USize](4, (ops(2) as ReversePositions).y)
      h.assert_eq[USize](1, (ops(3) as RotateLeft).steps)
      h.assert_eq[USize](1, (ops(4) as MovePosition).x)
      h.assert_eq[USize](4, (ops(4) as MovePosition).y)
      h.assert_eq[USize](3, (ops(5) as MovePosition).x)
      h.assert_eq[USize](0, (ops(5) as MovePosition).y)
      h.assert_eq[U8]('b', (ops(6) as RotateBasedOnLetter).letter)
      h.assert_eq[U8]('d', (ops(7) as RotateBasedOnLetter).letter)
    else
      h.fail("** Parse error")
    end

class iso _TestUndo is UnitTest
  fun name(): String => "undo"
  fun apply(h: TestHelper) =>
    /*
    NOTE: we don't have to do undo perfect
    We just need to undo so that redo ends up with same
    scrambled password (I think). It appears that rotate based
    on letter is a one way scramble.
    */
    // 0 -> 1
    h.assert_eq[String]("habcdefg", RotateBasedOnLetter('a').apply("abcdefgh"))
// 1 -> left 1 or 6
    h.assert_eq[String]("abcdefgh", RotateBasedOnLetter('a').undo("habcdefg"), "a")

    // 1 -> 2
    h.assert_eq[String]("ghabcdef", RotateBasedOnLetter('b').apply("abcdefgh"))
// 3 -> left 2
    h.assert_eq[String]("abcdefgh", RotateBasedOnLetter('b').undo("ghabcdef"), "b")

    // 2 -> 3
    h.assert_eq[String]("fghabcde", RotateBasedOnLetter('c').apply("abcdefgh"))
// 5 -> left 3
    h.assert_eq[String]("abcdefgh", RotateBasedOnLetter('c').undo("fghabcde"), "c")

    // 3 -> 4
    h.assert_eq[String]("efghabcd", RotateBasedOnLetter('d').apply("abcdefgh"))
// 7 -> left 4
    h.assert_eq[String]("abcdefgh", RotateBasedOnLetter('d').undo("efghabcd"), "d")

    // 4 -> 6
    h.assert_eq[String]("cdefghab", RotateBasedOnLetter('e').apply("abcdefgh"))
// 2 -> left 6
    h.assert_eq[String]("abcdefgh", RotateBasedOnLetter('e').undo("cdefghab"), "e")

    // 5 -> 7
    h.assert_eq[String]("bcdefgha", RotateBasedOnLetter('f').apply("abcdefgh"))
// 4 -> left 7
    h.assert_eq[String]("abcdefgh", RotateBasedOnLetter('f').undo("bcdefgha"), "f")
    //                                                             01234567

    // 6 -> 8
    h.assert_eq[String]("abcdefgh", RotateBasedOnLetter('g').apply("abcdefgh"))
// 6 -> left 8
    h.assert_eq[String]("abcdefgh", RotateBasedOnLetter('g').undo("abcdefgh"), "g")

    // 7 -> 9
    h.assert_eq[String]("habcdefg", RotateBasedOnLetter('h').apply("abcdefgh"))
// 0 -> left 9
    h.assert_eq[String]("abcdefgh", RotateBasedOnLetter('h').undo("habcdefg"), "h")
    //                                                             01234567

    h.assert_eq[String]("abcefghd", MovePosition(3, 7).apply("abcdefgh"))
    h.assert_eq[String]("abcdefgh", MovePosition(3, 7).undo("abcefghd"))
    h.assert_eq[String]("abgcdefh", MovePosition(6, 2).apply("abcdefgh"))
    h.assert_eq[String]("abcdefgh", MovePosition(6, 2).undo("abgcdefh"))

class iso _TestApply is UnitTest
  fun name(): String => "apply"
  fun apply(h: TestHelper) =>
    let s: Scrambler ref = Scrambler("abcde".clone())
    try
      let ops = s.parse(INPUT.sample().split("\n"))
      h.assert_eq[String]("ebcda", s(ops(0)))
      h.assert_eq[String]("edcba", s(ops(1)))
      h.assert_eq[String]("abcde", s(ops(2)))
      h.assert_eq[String]("bcdea", s(ops(3)))
      h.assert_eq[String]("bdeac", s(ops(4)))
      h.assert_eq[String]("abdec", s(ops(5)))
      h.assert_eq[String]("ecabd", s(ops(6)))
      h.assert_eq[String]("decab", s(ops(7)))

      // h.assert_eq[String]("ecabd", s.undo(ops(7)))
      // h.assert_eq[String]("abdec", s.undo(ops(6)))

      h.assert_eq[String]("bdehagcf", ReversePositions(3, 7).apply("bdefcgah"))
    else
      h.fail("** Apply error")
    end

class iso _TestPuzzle is UnitTest
  fun name(): String => "puzzle"
  fun apply(h: TestHelper) =>
    let s: Scrambler ref = Scrambler("abcdefgh".clone())
    try
      let ops = s.parse(INPUT.puzzle().split("\n"))
      for op in ops.values() do
        s(op)
        // h.assert_eq[String]("", s.pass, op.string())
      end
      h.assert_eq[String]("dgfaehcb", s.pass)
      for op in ops.reverse().values() do
        s.undo(op)
        // h.assert_eq[String]("", s.pass, op.string())
      end
      h.assert_eq[String]("abcdefgh", s.pass)
    else
      h.fail("** Apply error")
    end

class iso _TestPuzzle2 is UnitTest
  fun name(): String => "puzzle2"
  fun apply(h: TestHelper) =>
    let s: Scrambler ref = Scrambler("fbgdceah".clone())
    try
      let ops = s.parse(INPUT.puzzle().split("\n"))
      for op in ops.reverse().values() do
        s.undo(op)
        // h.assert_eq[String]("", s.pass, op.string())
      end
      h.assert_eq[String]("fdhgacbe", s.pass)
    else
      h.fail("** Apply error")
    end
