module Elm.Parser.FileTests exposing (..)

import Elm.Json.Encode
import Expect
import Json.Decode
import Json.Encode
import Elm.Parser.CombineTestUtil exposing (..)
import Elm.Parser.File as Parser exposing (file)
import Elm.Parser.Samples as Samples
import Elm.Parser as Parser
import Test exposing (..)
import Elm.Parser.State exposing (emptyState)
import Elm.Json.Decode as Elm
import Elm.Internal.RawFile exposing (RawFile(Raw))


all : Test
all =
    Test.concat
        [ describe "FileTests"
            [ Samples.allSamples
                |> List.indexedMap
                    (\n s ->
                        test ("sample " ++ toString (n + 1)) <|
                            \() ->
                                parseFullStringState emptyState s Parser.file |> Expect.notEqual Nothing
                    )
                |> Test.concat
            ]
        , describe "Error messages" <|
            [ test "failure on module name" <|
                \() ->
                    Parser.parse "module foo exposing (..)\nx = 1"
                        |> Expect.equal (Err [ "Could not continue parsing on location (1,0)" ])
            , test "failure on declaration" <|
                \() ->
                    Parser.parse "module Foo exposing (..)\n\ntype x = \n  1"
                        |> Expect.equal (Err [ "Could not continue parsing on location (2,-1)" ])
            , test "failure on declaration expression" <|
                \() ->
                    Parser.parse "module Foo exposing (..) \nx = \n  x + _"
                        |> Expect.equal (Err [ "Could not continue parsing on location (2,5)" ])
            ]
        , describe "FileTests - serialisation"
            [ Samples.allSamples
                |> List.indexedMap
                    (\n s ->
                        test ("sample " ++ toString (n + 1)) <|
                            \() ->
                                let
                                    parsed =
                                        parseFullStringState emptyState s Parser.file
                                            |> Maybe.map Raw

                                    roundTrip =
                                        parsed
                                            |> Maybe.map (Elm.Json.Encode.encode >> Json.Encode.encode 0)
                                            |> Maybe.andThen (Json.Decode.decodeString Elm.decode >> Result.toMaybe)
                                in
                                    Expect.equal parsed roundTrip
                    )
                |> Test.concat
            ]
        ]
