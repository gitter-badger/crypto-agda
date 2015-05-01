{-# OPTIONS --without-K #-}
open import Type using (Type)
open import Function
open import Data.Maybe
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality.NP
              using (_≡_; ap; _∙_)
open import Crypto.Schemes

-- Note that Message and Blinded could be made equal
-- to G. Because the code does not require it we keep
-- the most flexible version.
module Cipher.ElGamal.Generic
  (Message : Type) -- The type of messages
  (Blinded : Type) -- The type of blinded messages
  (ℤq      : Type) -- The type of exponenents
                   -- (the name ℤq, is only suggestive)
  (G       : Type) -- The type of the base cyclic group
  (g       : G)    -- The generator element

  -- Exponentation
  (_^_     : G → ℤq → G)

  -- Required for encryption
  (_*_     : G → Message → Blinded)

  -- Required for decryption
  (_/_     : Blinded → G → Message)
  where

PubKey     = G
SecKey     = ℤq
CipherText = G × Blinded
Rₖ         = ℤq
Rₑ         = ℤq

pub-of : SecKey → PubKey
pub-of x = g ^ x

key-gen : Rₖ → PubKey × SecKey
key-gen x = (pub-of x , x)

enc : PubKey → Message → Rₑ → CipherText
enc pk M r = α , β
  module enc where
    α = g  ^ r
    δ = pk ^ r
    β = δ  * M

dec : SecKey → CipherText → Message
dec x (α , β) = β / (α ^ x)

module Functional-correctness
    (/-*    : ∀ {α M} → (α * M) / α ≡ M)
    (^-comm : ∀ {α x y} → (α ^ x)^ y ≡ (α ^ y)^ x)
    where

    functionally-correct : ∀ x r m → dec x (enc (pub-of x) m r) ≡ m
    functionally-correct x r m = ap (λ z → (z * m) / ((g ^ r)^ x)) ^-comm ∙ /-*

    ElGamal-encryption : Pubkey-encryption
    ElGamal-encryption = record
                          { pkt = record
                             { PubKey = PubKey
                             ; SecKey = SecKey
                             ; Message = Message
                             ; CipherText = CipherText
                             ; Rₖ = Rₖ
                             ; Rₑ = Rₑ }
                          ; pko = record
                             { key-gen = key-gen
                             ; enc = enc
                             ; dec = λ s m → just (dec s m)
                             }
                          ; functionally-correct = λ x r m → ap just (functionally-correct x r m)
                          }

    module ElGamal-encryption = Pubkey-encryption ElGamal-encryption
