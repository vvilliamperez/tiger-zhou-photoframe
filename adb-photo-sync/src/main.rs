use std::process::Command;
use std::{env, thread, time};

const LOCAL_DIR: &str = "/home/pi/adb-photo-sync/";
const FRAME_DIR: &str = "/storage/emulated/0/Pictures/";

/// Get the frame's IP address from an environment variable
fn get_frame_ip() -> String {
    env::var("FRAME_IP").expect("❌ FRAME_IP environment variable not set")
}

/// Connect to the photo frame via ADB over Wi-Fi
fn adb_connect(frame_ip: &str) -> bool {
    println!("🔌 Connecting to ADB device at {}", frame_ip);
    let status = Command::new("adb")
        .arg("connect")
        .arg(format!("{}:5555", frame_ip))
        .status()
        .expect("Failed to execute adb connect");

    if status.success() {
        println!("✅ ADB connected successfully.");
        return true;
    } else {
        println!("❌ ADB connection failed.");
        return false;
    }
}

/// Run adb-sync to sync photos
fn sync_photos() {
    println!("📂 Starting adb-sync...");
    let status = Command::new("adb-sync")
        .arg(LOCAL_DIR)
        .arg(FRAME_DIR)
        .status()
        .expect("Failed to execute adb-sync");

    if status.success() {
        println!("✅ Sync completed successfully!");
        trigger_media_scan();
    } else {
        println!("❌ Sync failed.");
    }
}

/// Trigger Android Media Scanner to detect new photos
fn trigger_media_scan() {
    println!("🔄 Triggering Media Scanner...");
    let status = Command::new("adb")
        .arg("shell")
        .arg("am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///storage/emulated/0/Pictures/")
        .status()
        .expect("Failed to trigger media scan");

    if status.success() {
        println!("✅ Media scanner triggered.");
    } else {
        println!("❌ Failed to trigger media scanner.");
    }
}

fn main() {
    let frame_ip = get_frame_ip();

    loop {
        if adb_connect(&frame_ip) {
            sync_photos();
        }
        println!("⏳ Waiting 5 minutes before next sync...");
        thread::sleep(time::Duration::from_secs(300)); // 5 minutes
    }
}
