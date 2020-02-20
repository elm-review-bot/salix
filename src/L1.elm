module L1 exposing
    ( Basic(..)
    , Container(..)
    , Declarable(..)
    , L1
    , PropSpec(..)
    , PropSpecs
    , Properties
    , Property(..)
    , Restricted(..)
    , Type(..)
    , Unchecked(..)
    , defineProperties
    , emptyProperties
    , positionOfDeclarable
    , positionOfType
    )

import Dict exposing (Dict)
import Enum exposing (Enum)
import List.Nonempty exposing (Nonempty)


type Basic
    = BBool
    | BInt
    | BReal
    | BString


type Container pos ref
    = CList (Type pos ref)
    | CSet (Type pos ref)
    | CDict (Type pos ref) (Type pos ref)
    | COptional (Type pos ref)


type Type pos ref
    = TUnit pos
    | TBasic pos Basic
    | TNamed pos String ref
    | TProduct pos (Nonempty ( String, Type pos ref, Properties ))
    | TEmptyProduct pos
    | TContainer pos (Container pos ref)
    | TFunction pos (Type pos ref) (Type pos ref)


type Restricted
    = RInt
        { min : Maybe Int
        , max : Maybe Int
        , width : Maybe Int
        }
    | RString
        { minLength : Maybe Int
        , maxLength : Maybe Int
        , regex : Maybe String
        }


type Declarable pos ref
    = DAlias pos (Type pos ref) Properties
    | DSum pos (Nonempty ( String, List ( String, Type pos ref, Properties ) )) Properties
    | DEnum pos (Nonempty String) Properties
    | DRestricted pos Restricted Properties



-- Additional model properties.


{-| Defines the kinds of additional property that can be placed in the model.
-}
type PropSpec
    = PSString
    | PSEnum (Enum String)
    | PSQName
    | PSBool
    | PSOptional PropSpec


{-| A set of additional property kinds that can or must be defined against
the model.
-}
type alias PropSpecs =
    Dict String PropSpec


{-| Allows additional properties from a variety of possible kinds to be placed
in the model.
-}
type Property
    = PString String
    | PEnum (Enum String) String
    | PQName (List String) String
    | PBool Bool
    | POptional PropSpec (Maybe Property)


{-| A set of additional properties on the model.
-}
type alias Properties =
    Dict String Property


emptyProperties : Properties
emptyProperties =
    Dict.empty


defineProperties : List ( String, PropSpec ) -> List ( String, Property ) -> ( PropSpecs, Properties )
defineProperties notSet set =
    let
        notSetPropSpecs =
            List.foldl
                (\( name, spec ) accum -> Dict.insert name spec accum)
                Dict.empty
                notSet

        ( fullPropSpecs, properties ) =
            List.foldl
                (\( name, property ) ( specsAccum, propsAccum ) ->
                    ( Dict.insert name (asPropSpec property) specsAccum
                    , Dict.insert name property propsAccum
                    )
                )
                ( notSetPropSpecs, Dict.empty )
                set

        asPropSpec property =
            case property of
                PString _ ->
                    PSString

                PEnum enum _ ->
                    PSEnum enum

                PQName _ _ ->
                    PSQName

                PBool _ ->
                    PSBool

                POptional spec _ ->
                    PSOptional spec
    in
    ( fullPropSpecs, properties )



-- Model reference or property checking.


{-| Indicates that the model has not been checked.
-}
type Unchecked
    = Unchecked



-- Helper functions for extracting position info.


positionOfDeclarable : Declarable pos ref -> pos
positionOfDeclarable decl =
    case decl of
        DAlias pos _ _ ->
            pos

        DSum pos _ _ ->
            pos

        DEnum pos _ _ ->
            pos

        DRestricted pos _ _ ->
            pos


positionOfType : Type pos ref -> pos
positionOfType type_ =
    case type_ of
        TUnit pos ->
            pos

        TBasic pos _ ->
            pos

        TNamed pos _ _ ->
            pos

        TProduct pos _ ->
            pos

        TEmptyProduct pos ->
            pos

        TContainer pos _ ->
            pos

        TFunction pos _ _ ->
            pos


{-| The L1 model
-}
type alias L1 pos =
    List ( String, Declarable pos Unchecked )
