// This example demonstrates support for TLA+ INSTANCE in Quint
module InstanceEx {
  module A {
    var x: int
    var y: bool
    var z: str

    def F(a) = x + 1
    pure def G(b) = not(b)
  }

  // A state variable of InstanceEx
  var w: Set[int]

  // a value
  val MyY = z

  // Produce a new module that is an instance of A,
  // in which x is replaced with 33, y is replaced with MyY,
  // and z is replaced with z.
  // This is equivalent to TLA+'s instance:
  // A1 == INSTANCE A WITH x <- 33, y <- MyY, z <- z
  module A1 = A(x = 33, y = MyY, z = z)

  // now, we can access F and G via A1::F and A1::G
  val test_F = A1::F(10)
  val test_x = A::x

  // We can import the names from A1, provided that there are no collisions.
  // The effect of this import is similar to an anonymous local instance in TLA+:
  // LOCAL INSTANCE A WITH x <- 33, y <- MyY, z <- z
  import A1.*

  pure val test_G = G(true)

  // If we want to omit identity bindings such as z = z, we write:
  module A2 = A(x = 15, y = MyY, *)

  // the above is equivalent to TLA+'s instance:
  // A2 == INSTANCE A WITH x <- 15, y <- MyY
}
