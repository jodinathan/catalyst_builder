import 'package:catalyst_builder/catalyst_builder.dart';
import 'package:catalyst_builder_contracts/catalyst_builder_contracts.dart';
import 'package:test/test.dart';

class A {}

class B {}

class C {
  C(this.a);

  final A a;
}

void main() {
  group('ServiceContainer.scope', () {
    test('parent singleton resolves through the scope (cached at parent)', () {
      var parent = ServiceContainer()
        ..register<A>((_) => A())
        ..boot();

      var child = parent.scope();

      expect(child.resolve<A>(), same(parent.resolve<A>()));
    });

    test('scope-local service does not leak to the parent', () {
      var parent = ServiceContainer()..boot();

      var child = parent.scope(
        services: [
          LazyServiceDescriptor<B>((_) => B()),
        ],
      );

      expect(child.resolve<B>(), isA<B>());
      expect(parent.has<B>(), isFalse);
      expect(parent.tryResolve<B>(), isNull);
    });

    test('sibling scopes are isolated but share parent singletons', () {
      var parent = ServiceContainer()
        ..register<A>((_) => A())
        ..boot();

      var s1 = parent.scope(
        services: [LazyServiceDescriptor<B>((_) => B())],
      );
      var s2 = parent.scope(
        services: [LazyServiceDescriptor<B>((_) => B())],
      );

      expect(s1.resolve<B>(), isNot(same(s2.resolve<B>())));
      expect(s1.resolve<A>(), same(s2.resolve<A>()));
    });

    test('scope-local service can depend on a parent service', () {
      var parent = ServiceContainer()
        ..register<A>((_) => A())
        ..boot();

      var child = parent.scope(
        services: [
          LazyServiceDescriptor<C>((c) => C(c.resolve<A>())),
        ],
      );

      expect(child.resolve<C>().a, same(parent.resolve<A>()));
    });

    test('has and resolveByTag fall back to the parent', () {
      const tag = #thing;
      var parent = ServiceContainer()
        ..register<A>((_) => A(), const Service(tags: [tag]))
        ..boot();

      var child = parent.scope();

      expect(child.has<A>(), isTrue);
      expect(child.resolveByTag(tag), contains(parent.resolve<A>()));
    });
  });
}
