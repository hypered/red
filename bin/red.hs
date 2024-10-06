module Main
  ( main
  ) where

import Data.List (dropWhileEnd)
import Options.Applicative qualified as A
import Protolude
import System.Environment
import System.FilePath ((</>))
import System.IO.Temp (withSystemTempDirectory)
import System.Process
import Text.Blaze.Html.Renderer.Utf8 qualified as Utf8 (renderHtml)
import Text.Blaze.Html5 (Html, (!))
import Text.Blaze.Html5 qualified as H
import Text.Blaze.Html5.Attributes qualified as A
import Text.HTML.TagSoup

--------------------------------------------------------------------------------
main :: IO ()
main = A.execParser opts >>= run

--------------------------------------------------------------------------------
data Command
  = Highlight Mode FilePath
  | Extract -- Mainly used for debugging the underlying extraction logic.
  deriving (Show)

data Mode
  = -- | Output what Neovim does
    Neovim
  | -- | Output a standalone HTML document
    Standalone
  | -- | Output only the code block
    CodeBlock
  deriving (Show)

opts :: A.ParserInfo Command
opts =
  A.info
    (parseCommand <**> A.helper)
    ( A.fullDesc
        <> A.progDesc "red - syntax highlighting using Neovim"
        <> A.header "red"
    )

parseCommand :: A.Parser Command
parseCommand =
  A.hsubparser
    ( A.command "highlight" (A.info (Highlight <$> neovimModeParser <*> argumentFilePath) (A.progDesc "Highlight a file"))
        <> A.command "extract" (A.info (pure Extract) (A.progDesc "Extract code block from stdin"))
    )

neovimModeParser :: A.Parser Mode
neovimModeParser =
  A.flag CodeBlock Neovim (A.long "neovim" <> A.help "Highlight using neovim")
    <|> A.flag CodeBlock Standalone (A.long "standalone" <> A.help "Standalone highlight mode")

argumentFilePath :: A.Parser FilePath
argumentFilePath = A.argument A.str (A.metavar "FILENAME")

--------------------------------------------------------------------------------
run :: Command -> IO ()
run command =
  case command of
    Highlight Neovim fn ->
      withSystemTempDirectory "red" $ \dir -> do
        let outputPath = dir </> "document.html"
        highlight fn outputPath
        content <- readFile outputPath
        putStr content
    Highlight Standalone fn ->
      withSystemTempDirectory "red" $ \dir -> do
        let outputPath = dir </> "document.html"
        highlight fn outputPath
        content <- readFile outputPath
        putStr . Utf8.renderHtml . document fn $ extract content
    Highlight CodeBlock fn ->
      withSystemTempDirectory "red" $ \dir -> do
        let outputPath = dir </> "document.html"
        highlight fn outputPath
        content <- readFile outputPath
        putStr . Utf8.renderHtml $ extract content
    Extract -> do
      content <- getContents
      putStr . Utf8.renderHtml $ extract content

--------------------------------------------------------------------------------

-- | Use Neovim to syntax highlight a file. This is similar to `nix-build -A
-- highlight`.
highlight :: FilePath -> FilePath -> IO ()
highlight fn outputPath = do
  neovimBin <- getEnv "RED_NEOVIM_BIN"
  neovimConf <- getEnv "RED_NEOVIM_CONF"
  void $ highlight' neovimBin neovimConf fn outputPath

highlight' :: FilePath -> FilePath -> FilePath -> FilePath -> IO ExitCode
highlight' neovimBin neovimConf fn outputFile = do
  let args =
        [ "--clean"
        , "-es"
        , "-u"
        , neovimConf
        , "-i"
        , "NONE"
        , "-c"
        , "set columns=90"
        , "-c"
        , "TOhtml"
        , "-c"
        , "w! " ++ outputFile
        , "-c"
        , "qa!"
        , fn
        ]
  let process = proc neovimBin args
  (_, _, _, h) <- createProcess process {std_out = NoStream, std_err = NoStream}
  waitForProcess h

--------------------------------------------------------------------------------

-- | Extract the code part of an HTML document generated by Neovim's TOhtml
-- function. We could simply remove all the lines of text until the first <pre>
-- and after the last </pre>, but we instead use Tagsoup and represent the end
-- result with blaze-html.
extract :: Text -> Html
extract content =
  getPreBlock content & parse & markup

--------------------------------------------------------------------------------

-- | Returns a tagsoup that should contain only the <pre>...</pre> content of
-- the page. No attempt to validate the structure of the page beforehand is
-- done.
getPreBlock :: Text -> [Tag Text]
getPreBlock content =
  parseTags content
    & canonicalizeTags
    & dropWhile (~/= TagOpen @Text "pre" [])
    & dropWhileEnd (~/= TagClose @Text "pre")

--------------------------------------------------------------------------------

-- | Represent a dumbed-down HTML element, but enough te represent the
-- Neovim-generated syntax highlighted code.
data Elem
  = Text Text
  | -- | A span, with a class name and a text content. This includes
    -- the closing tag.
    Span Text Text
  deriving (Show)

-- | Turn a tagsoup as obtained by "getPreBlock" to our simple HTML
-- representation.
parse :: [Tag Text] -> [Elem]
parse (TagOpen "pre" [] : rest) = go rest
 where
  go (TagText t : rst) = Text t : go rst
  go (TagOpen "span" [("class", c)] : TagText t : TagClose "span" : rst) =
    Span c t : go rst
  go [TagClose "pre"] = []
  go _ = panic "Unexpected Tagsoup element."
parse _ = panic "Unexpected first Tagsoup element."

--------------------------------------------------------------------------------

-- | Convert our simple HTML representation to blaze-html.
markup :: [Elem] -> Html
markup = mconcat . map go
 where
  go (Text t) = H.text t
  go (Span c t) = H.span ! A.class_ (H.toValue c) $ H.text t

--------------------------------------------------------------------------------

-- | Wrap some HTML content in a complete document.
document :: FilePath -> Html -> Html
document fn content = do
  H.docType
  H.html $ do
    H.head $ do
      H.meta ! A.charset "UTF-8"
      H.title $ H.string fn
      H.style $ H.text style
    H.body $
      H.pre $
        H.code content

-- | CSS are copied from the Neovim-generated HTML, with font and spacing tweaks to
-- match my xterm output (switching back and forth between a fullscreen firefox and
-- the original code displayed in vim is almost exactly the same).
style :: Text
style =
  unlines
    [ "* {font-family: monospace}"
    , "body {background-color: #ffffff; color: #000000; margin: 0px; padding: 0px;}"
    , ".String {color: #0000c0}"
    , ".hsImportModuleName {}"
    , ".Statement {color: #c00000}"
    , ".Special {color: #8700ff}"
    , ".hsImportGroup {}"
    , ".Constant {color: #0000c0}"
    , ".hsDelimiter {}"
    , ".PreProc {color: #c000c0}"
    , ".Comment {color: #6c6c6c}"
    , ".ConId {}"
    , ".VarId {}"
    , ".hsImportList {}"
    , ".Type {color: #c00000}"
    , ".Todo {background-color: #ffff00; color: #000000}"
    , "pre {margin: 0px; width: 93.10ch; white-space: pre-wrap; word-break: break-all; padding: 0px; font-size:11.5px; letter-spacing: 0.08px; margin-top: -0.5px; margin-left: -0.5px;}"
    ]
