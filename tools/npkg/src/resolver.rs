pub fn resolve(package: &str) -> Result<Vec<String>, String> {
    Ok(vec![package.to_string()])
}
