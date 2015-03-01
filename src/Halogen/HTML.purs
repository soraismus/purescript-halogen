module Halogen.HTML
  ( HTML()
  , Attribute(..)
  
  , MouseEvent()
  
  , text
  
  , button
  , button'
  , div
  , div'
  
  , renderHtml
  ) where

import Data.Array (map, null)
import Data.Foldable (foldMap)
import Data.Function (runFn3)
import Data.Foldable (for_)

import Control.Monad.Eff
import Control.Monad.ST

import Halogen.VirtualDOM

data MouseEvent

-- TODO: add more event types
data Attribute i
  = OnClick (MouseEvent -> i)

instance functorAttribute :: Functor Attribute where
  (<$>) f (OnClick g) = OnClick (f <<< g)

-- | The `HTML` type represents HTML documents before being rendered to the virtual DOM, and ultimately,
-- | the actual DOM.
-- |
-- | This representation is useful because it supports various typed transformations. It also gives a 
-- | strongly-typed representation for the events which can be generated by a document.
-- |
-- | The type parameter `i` represents the type of events which can be generated by this document.
data HTML i
  = Text String
  | Element String [Attribute i] [HTML i]
    
instance functorHTML :: Functor HTML where
  (<$>) _ (Text s) = Text s
  (<$>) f (Element name attribs children) = Element name (map (f <$>) attribs) (map (f <$>) children)

-- | Render a `HTML` document to a virtual DOM node
renderHtml :: forall i eff. (i -> Eff eff Unit) -> HTML i -> VTree
renderHtml _ (Text s) = vtext s
renderHtml k (Element name attribs children) = vnode name props (map (renderHtml k) children)
  where
  props :: Props
  props | null attribs = emptyProps
        | otherwise = runProps do 
                        stp <- newProps
                        for_ attribs (addProp stp)
                        return stp
    where    
    addProp :: forall h eff. STProps h -> Attribute i -> Eff (st :: ST h | eff) Unit
    addProp props (OnClick f) = runFn3 handlerProp "onclick" (k <<< f) props

text :: forall i. String -> HTML i
text = Text

-- TODO: add remaining HTML elements

button :: forall i. [Attribute i] -> [HTML i] -> HTML i
button = Element "button"

button' :: forall i. [HTML i] -> HTML i
button' = button []

div :: forall i. [Attribute i] -> [HTML i] -> HTML i
div = Element "div"

div' :: forall i. [HTML i] -> HTML i
div' = div []
