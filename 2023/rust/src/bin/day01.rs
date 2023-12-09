use anyhow::{anyhow, Context, Result};
use rust_aoc_2023::get_resource_lines;

pub fn parse_calibration_value_p1(text: impl Into<String>) -> Result<u32> {
    let text_val = text.into();
    let a = text_val.chars().enumerate().find(|&(_, c)| c.is_numeric());
    let b = text_val
        .chars()
        .rev()
        .enumerate()
        .find(|&(_, c)| c.is_numeric())
        .map(|(i, c)| (text_val.len() - i - 1, c));

    match (a, b) {
        (Some((_, ac)), Some((_, bc))) => {
            let av = ac.to_digit(10).context("invalid first char digit")?;
            let bv = bc.to_digit(10).context("invalid second char digit")?;
            Ok(av * 10 + bv)
        }
        _ => Err(anyhow!("invalid calibration input, no digits found")),
    }
}

pub fn match_digit(text: impl Into<String>) -> Option<i32> {
    let text_val = text.into();
    match text_val {
        _ if text_val.starts_with("one") || text_val.starts_with('1') => Some(1),
        _ if text_val.starts_with("two") || text_val.starts_with('2') => Some(2),
        _ if text_val.starts_with("three") || text_val.starts_with('3') => Some(3),
        _ if text_val.starts_with("four") || text_val.starts_with('4') => Some(4),
        _ if text_val.starts_with("five") || text_val.starts_with('5') => Some(5),
        _ if text_val.starts_with("six") || text_val.starts_with('6') => Some(6),
        _ if text_val.starts_with("seven") || text_val.starts_with('7') => Some(7),
        _ if text_val.starts_with("eight") || text_val.starts_with('8') => Some(8),
        _ if text_val.starts_with("nine") || text_val.starts_with('9') => Some(9),
        _ if text_val.starts_with("zero") || text_val.starts_with('0') => Some(0),
        _ => None,
    }
}

pub fn parse_calibration_value_p2(text: impl Into<String>) -> Result<i32> {
    let text_val = text.into();
    // loop from [i...n] for i = [0...n] until digit found
    let mut a: Option<i32> = None;
    for s in 0..text_val.len() {
        a = match_digit(&text_val[s..]);
        if a.is_some() {
            break;
        }
    }
    // loop from [i...n] for i = [n-1...0] until digit found
    let mut b: Option<i32> = None;
    for s in (0..text_val.len()).rev() {
        b = match_digit(&text_val[s..]);
        if b.is_some() {
            break;
        }
    }

    match (a, b) {
        (Some(av), Some(bv)) => Ok(av * 10 + bv),
        _ => Err(anyhow!("invalid calibration input: {}", text_val)),
    }
}

fn part1() -> Result<()> {
    let value = get_resource_lines("day01.txt")?
        .iter()
        .map(|l| parse_calibration_value_p1(l).unwrap())
        .fold(0, |acc, v| acc + v);
    println!("part 1: {}", value);
    Ok(())
}

fn part2() -> Result<()> {
    let value = get_resource_lines("day01.txt")?
        .iter()
        .map(|l| parse_calibration_value_p2(l).unwrap())
        .fold(0, |acc, v| acc + v);
    println!("part 2: {}", value);
    Ok(())
}

fn main() -> Result<()> {
    println!("AOC 2023 Day 1");
    part1()?;
    part2()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_calibration_value() {
        assert_eq!(parse_calibration_value_p2("q1abc2").unwrap(), 12i32);
        assert_eq!(parse_calibration_value_p2("1abc").unwrap(), 11i32);
        assert!(parse_calibration_value_p2("").is_err());
        assert_eq!(parse_calibration_value_p2("1234567890").unwrap(), 10i32);
        assert_eq!(parse_calibration_value_p2("-5aaaaa5").unwrap(), 55i32);
    }

    #[test]
    fn test_example_data() {
        let lines = get_resource_lines("day01.example.txt").unwrap();
        assert_eq!(parse_calibration_value_p2(&lines[0]).unwrap(), 12i32);
        assert_eq!(parse_calibration_value_p2(&lines[1]).unwrap(), 38i32);
        assert_eq!(parse_calibration_value_p2(&lines[2]).unwrap(), 15i32);
        assert_eq!(parse_calibration_value_p2(&lines[3]).unwrap(), 77i32);
        assert_eq!(parse_calibration_value_p2(&lines[4]).unwrap(), 29i32);
        assert_eq!(parse_calibration_value_p2(&lines[5]).unwrap(), 83i32);
        assert_eq!(parse_calibration_value_p2(&lines[6]).unwrap(), 13i32);
        assert_eq!(parse_calibration_value_p2(&lines[7]).unwrap(), 24i32);
        assert_eq!(parse_calibration_value_p2(&lines[8]).unwrap(), 42i32);
        assert_eq!(parse_calibration_value_p2(&lines[9]).unwrap(), 14i32);
        assert_eq!(parse_calibration_value_p2(&lines[10]).unwrap(), 76i32);
    }

    #[test]
    fn test_match_digits() {
        assert_eq!(match_digit("one123"), Some(1));
        assert_eq!(match_digit("two342"), Some(2));
        assert_eq!(match_digit("three235eas"), Some(3));
        assert_eq!(match_digit("fourasdjfa"), Some(4));
        assert_eq!(match_digit("fiveasdfasd33"), Some(5));
        assert_eq!(match_digit("six388383"), Some(6));
        assert_eq!(match_digit("sevensevenseven"), Some(7));
        assert_eq!(match_digit("eightas"), Some(8));
        assert_eq!(match_digit("ninedd"), Some(9));
        assert_eq!(match_digit("zerooorez"), Some(0));

        assert_eq!(match_digit("1two3four"), Some(1));
        assert_eq!(match_digit("9939"), Some(9));

        assert_eq!(match_digit("otwena"), None);
    }
}
