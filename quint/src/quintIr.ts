/*
 * Intermediate representation of Quint. It almost mirrors the IR of Apalache,
 * which assumes that module instances are flattened. Quint extends the Apalache IR
 * by supporting hierarchical modules and instances.
 *
 * Igor Konnov, 2021
 *
 * Copyright (c) Informal Systems 2021. All rights reserved.
 * Licensed under the Apache 2.0.
 * See License.txt in the project root for license information.
 */

import { QuintType } from './quintTypes'

/**
 * Quint expressions, declarations and types carry a unique identifier, which can be used
 * to recover expression metadata such as source information, annotations, etc.
 */
export interface WithId {
  id: bigint
}

/**
 * An error message that needs a source map to resolve the actual sources.
 */
export interface IrErrorMessage {
  explanation: string;
  refs: bigint[];
}

/**
 * Quint expressions and declarations carry an optional type tag.
 * If a type tag is missing, it means that the type has not been computed yet.
 */
interface WithOptionalTypeAnnotation {
  typeAnnotation?: QuintType
}

/**
 * Some declarations require a type tag.
 */
interface WithTypeAnnotation {
  typeAnnotation: QuintType
}

interface WithOptionalDoc {
  /** optionally, docstrings for the operator */
  doc?: string,
}

/**
 * Operator qualifier, which refines a mode:
 *
 *  - val: an expression over constants and state variables (when impure),
 *
 *  - def: a parameterized expression over constants, state variables
 *    (when impure),
 *    and definition parameters. When the defined expression produces a Boolean
 *    value, you should use `pred` instead. However, this is only a convention,
 *    not a requirement.
 *
 *  - nondet: a non-parameterized binding,
 *    state variables, and definition parameters. This expression must contain
 *    at least one assignment or an action operator.
*
 *  - action: a (possibly parameterized) expression over constants,
 *    state variables, and definition parameters. This expression must contain
 *    at least one assignment or an action operator.
 *
 *  - temporal: a (possibly parameterized) expression over constants,
 *    state variables, and definition parameters. This expression must contain
 *    at least one temporal operator.
 *
 * A qualifier is purely a language feature that we introduced for convenience.
 * Given an operator definition, we can compute its qualifier automatically.
 * However, it is often hard for the specification reader to figure out the
 * TLA+ level of an expression. So we optimize specifications for the reader
 * by requiring an explicit qualifier.
 */
export type OpQualifier =
  'pureval' | 'puredef' | 'val' | 'def' |
  'pred' | 'nondet' | 'action' | 'run' | 'temporal'

export interface QuintName extends WithId {
  /** Expressions kind ('name' -- name reference) */
  kind: 'name',
  /** A name of: a variable, constant, parameter, user-defined operator */
  name: string,
}

export interface QuintBool extends WithId {
  /** Expressions kind ('bool' -- a boolean literal) */
  kind: 'bool',
  /** The boolean literal value */
  value: boolean,
}

export interface QuintInt extends WithId {
  /** Expressions kind ('int' -- an integer literal) */
  kind: 'int',
  /** The integer literal value */
  value: bigint,
}

export interface QuintStr extends WithId {
  /** Expressions kind ('str' -- a string literal) */
  kind: 'str',
  /** The string literal value */
  value: string,
}

export interface QuintApp extends WithId {
  /** Expressions kind ('app' -- operator application) */
  kind: 'app',
  /** The name of the operator being applied */
  opcode: string,
  /** A list of arguments to the operator */
  args: QuintEx[],
}

export interface QuintLambda extends WithId {
  /** Expressions kind ('lambda' -- operator abstraction) */
  kind: 'lambda',
  /** Identifiers for the formal parameters */
  params: string[],
  /** The qualifier for the defined operator */
  qualifier: OpQualifier,
  /** The definition body */
  expr: QuintEx,
}

export interface QuintLet extends WithId {
  /** Expressions kind ('let' -- a let-in binding defined via 'def', 'val', etc.) */
  kind: 'let',
  /** The operator being defined to be used in the body */
  opdef: QuintOpDef,
  /** The body */
  expr: QuintEx,
}

/**
 * Discriminated union of Quint expressions.
 */
export type QuintEx = QuintName | QuintBool | QuintInt | QuintStr | QuintApp | QuintLambda | QuintLet

/**
 * A user-defined operator that is defined via one of the qualifiers:
 * val, def, pred, action, or temporal.
 * Note that QuintOpDef does not have any formal parameters.
 * If an operator definition has formal parameters, then `expr`
 * should be a lambda expression over those parameters.
 */
export interface QuintOpDef extends WithId, WithOptionalTypeAnnotation, WithOptionalDoc {
  /** definition kind ('def' -- operator definition) */
  kind: 'def',
  /** definition name */
  name: string,
  /** definition qualifier: 'val', 'def', 'action', 'temporal' */
  qualifier: OpQualifier,
  /** expression to be associated with the definition */
  expr: QuintEx,
}

export interface QuintConst extends WithId, WithTypeAnnotation {
  /** definition kind ('const') */
  kind: 'const',
  /** name of the constant */
  name: string,
}

export interface QuintVar extends WithId, WithTypeAnnotation {
  /** definition kind ('var') */
  kind: 'var',
  /** name of the variable */
  name: string
}

export interface QuintAssume extends WithId {
  /** definition kind ('assume') */
  kind: 'assume',
  /** name of the assumption, may be '_' */
  name: string,
  /** an expression to associate with the name */
  assumption: QuintEx
}

/** QuintTypeDefs represent both type aliases and abstract types
 *
 * - Abstract types do not have an associated `type`
 * - Type aliases always have an associated `type`
 */
export interface QuintTypeDef extends WithId {
  /** definition kind ('typedef') */
  kind: 'typedef',
  /** name of a type alias */
  name: string,
  /** type to associate with the alias (none for uninterpreted type) */
  type?: QuintType
}

/** A QuintTypeAlias is a sub-type of QuintTypeDef which always has an associated type */
export interface QuintTypeAlias extends QuintTypeDef {
  /** type to associate with the alias (none for uninterpreted type) */
  type: QuintType
}

export function isTypeAlias(def: any): def is QuintTypeAlias {
  return def.kind === 'typedef' && def.type
}

export interface QuintImport extends WithId {
  /** definition kind ('import') */
  kind: 'import',
  /** name to import, or '*' to denote all */
  name: string,
  /** path to the module, e.g., Foo.Bar */
  path: string
}

export interface QuintInstance extends WithId {
  /** definition kind ('instance') */
  kind: 'instance',
  /** instance name */
  name: string,
  /** the name of the module to instantiate */
  protoName: string,
  /** how to override constants and variables */
  overrides: [string, QuintEx][],
  /** whether to use identity substitution on missing names */
  identityOverride: boolean
}

export interface QuintModuleDef extends WithId {
  /** definition kind ('module') */
  kind: 'module',
  /** nested module */
  module: QuintModule
}

/**
 * Definition: constant, state variable, operator definition, assumption, instance, module.
 */
export type QuintDef = (
  QuintOpDef
  | QuintConst
  | QuintVar
  | QuintAssume
  | QuintTypeDef
  | QuintImport
  | QuintInstance
  | QuintModuleDef
) & WithOptionalDoc

export function isAnnotatedDef(def: any): def is WithTypeAnnotation {
  return def.typeAnnotation !== undefined
}

/**
 * Module definition.
 */
export interface QuintModule extends WithId {
  name: string,
  defs: QuintDef[]
}
