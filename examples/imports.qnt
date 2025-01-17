// this file demonstrates namespaces of modules and imports

module root {
  // Math is a stateless module: Its definitions may be imported
  module Math {
    def sqr(x) = x * x
    def pow(x, y) = x^y
  }

  // We can access definitions of a stateless module
  // via path notation.
  def cube(x) = Math::pow(x, 3)

  module A {
    // we cannot access sqr here, as we have not imported it yet
    // val test_sqr_before = sqr(3) == 9
    //                       ^^^ error: sqr is not found

    // import all names from Math, namely, sqr and pow
    import Math.*

    // we can access sqr here and everywhere in the name scope of A
    val test_sqr = sqr(2) == 4
  }

  module B {
    import A.*

    // Import introduces names in the module lookup table,
    // but it is not transitive. Hence, we cannot access sqr here.
    // val test_sqr = sqr(2) == 4
    //                ^^^ error: sqr is not available

    // however, we can access test_sqr
    val test_test_sqr = test_sqr

    module BB {
      // Following definitions are commented out in favor of discussion (#87)

      // we can access test_test_sqr, as it belongs to the parent module
      // val test_test_test_sqr = test_test_sqr
      // we can access test_sqr too, as it is imported in the parent module
      // val inner_test_sqr = test_sqr
    }

    // All modules are always accessible via imports or via the path notation.
    // There are no 'LOCAL' or 'private' modules.
    // By convention, the modules that are starting with the prefix '_'
    // should not be accessed from outside of a module.
    // The language is not going to police you, this is just a convention.
    module _Internals {
      val foo = 11
    }

    val test_foo = _Internals::foo
  }

  // module C is stateful, it cannot be imported
  module C {
    var n: int

    module CC {
      var m: int

      // Following definitions are commented out in favor of discussion (#87)
      // we can access the state variable of the parent module
      // val nn = n * n
    }
  }

  module D {
    // import C.*
    //        ^ error: C is stateful
  }

  module test {
    // demonstrate that the same module may be imported via different paths
    module basics {
      def double(x) = 2 * x
    }

    module spec {
      import basics.*

      def quad(x) = double(double(x))
    }

    // first, we import `basics`, as we need `double`
    // (let's pretend that we do not know that `spec` imports `basics`)
    import basics.*
    // second, we import `spec`, as we need `quad`
    import spec.*

    def quadShouldDoubleTwice = {
      Set(1, 2, 3).forall(i => quad(i) == double(i) + double(i))
    }
  }
}
