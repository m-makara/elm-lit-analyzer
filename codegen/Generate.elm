module Generate exposing (main)

{-| -}

import Elm exposing (Expression)
import Elm.Annotation as Annotation exposing (Annotation)
import Gen.CodeGen.Generate as Generate
import Gen.Html
import Gen.Html.Attributes exposing (attribute)
import Gen.String
import Json.Decode
import Json.Decode.Pipeline as Pipeline


type TypeOption
    = TypeNumber
    | TypeString
    | TypeBoolean


type alias ReactiveProperty =
    { name : String
    , typeOption : TypeOption
    }


type Reactive
    = ReactAtr ReactiveAttribute
    | ReactProp ReactiveProperty


type alias ReactiveAttribute =
    { name : String
    , attribute : String
    , typeOption : TypeOption
    }


type alias Flags =
    { reactiveProperties : List Reactive
    }


decodeTypeOption : String -> Json.Decode.Decoder TypeOption
decodeTypeOption s =
    case s of
        "Number" ->
            Json.Decode.succeed TypeNumber

        "Boolean" ->
            Json.Decode.succeed TypeBoolean

        "String" ->
            Json.Decode.succeed TypeString

        _ ->
            Json.Decode.fail "Unknown"


decodeReactiveAttribute : String -> Json.Decode.Decoder ReactiveAttribute
decodeReactiveAttribute attribute =
    Json.Decode.succeed ReactiveAttribute
        |> Pipeline.required "name" Json.Decode.string
        |> Pipeline.hardcoded attribute
        |> Pipeline.required "typeOption" (Json.Decode.string |> Json.Decode.andThen decodeTypeOption)


decodeReactiveProperty : Json.Decode.Decoder ReactiveProperty
decodeReactiveProperty =
    Json.Decode.succeed ReactiveProperty
        |> Pipeline.required "name" Json.Decode.string
        |> Pipeline.required "typeOption" (Json.Decode.string |> Json.Decode.andThen decodeTypeOption)


decodeReactive : Json.Decode.Decoder Reactive
decodeReactive =
    Json.Decode.field "attribute" (Json.Decode.maybe Json.Decode.string)
        |> Json.Decode.andThen
            (\attr ->
                case attr of
                    Just attribute ->
                        decodeReactiveAttribute attribute |> Json.Decode.map ReactAtr

                    Nothing ->
                        decodeReactiveProperty |> Json.Decode.map ReactProp
            )


decodeFlags : Json.Decode.Decoder Flags
decodeFlags =
    Json.Decode.succeed Flags
        |> Pipeline.required "reactiveProperties"
            (Json.Decode.list decodeReactive)


handleFlags : Flags -> List Generate.File
handleFlags { reactiveProperties } =
    [ file reactiveProperties
    ]


main : Program Json.Decode.Value () ()
main =
    Generate.fromJson decodeFlags handleFlags


generateStuff : List Reactive -> Elm.Expression -> List Expression
generateStuff reactiveList data =
    reactiveList
        |> List.map
            (\reactive ->
                case reactive of
                    ReactAtr { attribute, typeOption } ->
                        case typeOption of
                            TypeNumber ->
                                Gen.Html.Attributes.call_.attribute (Elm.string attribute) <| Gen.String.call_.fromFloat (Elm.get attribute data)

                            TypeString ->
                                Gen.Html.Attributes.call_.attribute (Elm.string attribute) (Elm.get attribute data)

                            TypeBoolean ->
                                Gen.Html.Attributes.call_.attribute (Elm.string attribute) <|
                                    Elm.ifThen (Elm.get attribute data) (Elm.string "true") (Elm.string "false")

                    ReactProp { name, typeOption } ->
                        case typeOption of
                            TypeNumber ->
                                Gen.Html.Attributes.property name <| Gen.String.call_.fromFloat (Elm.get name data)

                            TypeString ->
                                Gen.Html.Attributes.property name (Elm.get name data)

                            TypeBoolean ->
                                Elm.ifThen (Elm.get name data)
                                    (Gen.Html.Attributes.property name <| Elm.string "true")
                                    (Gen.Html.Attributes.property name <| Elm.string "false")
            )


file : List Reactive -> Elm.File
file reactive =
    let
        test =
            Annotation.function [ generateRecordAnnotation reactive ] (Gen.Html.annotation_.html (Annotation.var "msg"))
    in
    Elm.file [ "MyElement" ]
        [ Elm.declaration "view" <|
            Elm.withType test <|
                Elm.fn ( "data", Nothing )
                    (\data -> Gen.Html.node "my-element" (generateStuff reactive data) [])
        ]


generateRecordAnnotation : List Reactive -> Annotation
generateRecordAnnotation reactiveList =
    let
        typeAnnotation opt =
            case opt of
                TypeNumber ->
                    Annotation.float

                TypeString ->
                    Annotation.string

                TypeBoolean ->
                    Annotation.bool
    in
    reactiveList
        |> List.map
            (\prop ->
                case prop of
                    ReactAtr { attribute, typeOption } ->
                        ( attribute, typeAnnotation typeOption )

                    ReactProp { name, typeOption } ->
                        ( name, typeAnnotation typeOption )
            )
        |> Annotation.record
