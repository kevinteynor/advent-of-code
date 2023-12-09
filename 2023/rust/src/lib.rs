use anyhow::{Context, Result};
use std::fs::File;
use std::io::{self, BufRead};
use std::path::{Path, PathBuf};

pub fn get_resource_path<P>(filename: P) -> Result<PathBuf>
where
    P: AsRef<Path>,
{
    let mut p = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    p.push("../resources");
    p.push(filename);
    Ok(p)
}

pub fn get_resource_lines<P>(filename: P) -> Result<Vec<String>>
where
    P: AsRef<Path>,
{
    let path = get_resource_path(filename)?;
    let file = File::open(path.as_path())?;
    let reader = io::BufReader::new(file);
    reader
        .lines()
        .collect::<Result<Vec<String>, io::Error>>()
        .context("Failed to read lines from file")
}

#[test]
fn test_get_resource_path() {
    println!(
        "{}",
        get_resource_path("day01.example.txt").unwrap().display()
    );
}
