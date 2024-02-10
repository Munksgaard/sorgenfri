use base64;
use ring::rand::SecureRandom;
use ring::{digest, pbkdf2, rand};
use std::num::NonZeroU32;

const N_ITER: u32 = 100_000;

const CREDENTIAL_LEN: usize = digest::SHA512_OUTPUT_LEN;

fn new_salt() -> Result<[u8; CREDENTIAL_LEN], String> {
    let rng = rand::SystemRandom::new();

    let mut salt = [0u8; CREDENTIAL_LEN];
    rng.fill(&mut salt)
        .map_err(|_| String::from("Could not create salt"))?;

    Ok(salt)
}

/// Returns the base64 representation of `password` hashed with `salt`
#[rustler::nif]
fn hash_password(password: &str) -> Result<(String, String), String> {
    let n_iter = NonZeroU32::new(N_ITER).unwrap();

    let salt = new_salt()?;

    let mut hash = [0u8; CREDENTIAL_LEN];
    pbkdf2::derive(
        pbkdf2::PBKDF2_HMAC_SHA512,
        n_iter,
        &salt,
        password.as_bytes(),
        &mut hash,
    );
    Ok((base64::encode(hash), base64::encode(salt)))
}

#[rustler::nif]
pub fn verify_password(password: &str, password_hash: &str, salt: &str) -> Result<(), String> {
    let n_iter = NonZeroU32::new(N_ITER).unwrap();

    let decoded_hash =
        base64::decode(password_hash).map_err(|_| String::from("Could not decode base64"))?;
    let decoded_salt = base64::decode(salt).map_err(|_| String::from("Could not decode base64"))?;
    pbkdf2::verify(
        pbkdf2::PBKDF2_HMAC_SHA512,
        n_iter,
        &decoded_salt,
        password.as_bytes(),
        &decoded_hash,
    )
    .map_err(|_| String::from("Could not verify password"))
}

rustler::init!(
    "Elixir.Sorgenfri.PasswordHashingNIF",
    [hash_password, verify_password]
);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn verify_password_works() {
        assert_eq!(Ok(()), verify_password("yrsadrengen", "TnOIqxyhoyXBqqLX5uSJfiWhD7XTukVDZhaUZgtJi3zePKFHZOMWd8g6xODMCt/WJ+OOtJIJrdZW8iClsahqPw==", "QuJ+GhS2jFGO9znM6TCU32ywcgZ7RBsm5pqFk3F7j5edkiTj2K4KjMxZ/vWAASnGp90eNScXGpXPQGAh/aZ5BQ=="))
    }
}
