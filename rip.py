import cdio
import fcntl
import logging
import makemkv
import os
import pycdio
import time


# These are macros from linux/cdrom.h
CDROM_DRIVE_STATUS = 0x5326

CDS_NO_DISC = 1
CDS_TRAY_OPEN = 2
CDS_DRIVE_NOT_READY = 3
CDS_DISC_OK = 4


LOGGING_FORMAT = '[%(levelname)s] %(message)s'
logging.getLogger().setLevel(logging.INFO)
logging.basicConfig(format=LOGGING_FORMAT)


def rip_with_makemkv(drive_path: str):
    mm = makemkv.MakeMKV(drive_path)
    logging.info(f"reading disc info from {drive_path}")
    disc_info = mm.info()
    disc_name = disc_info.get("disc").get("name")
    logging.info(f"got a disc named {disc_name}")
    disc_titles = disc_info.get("titles")
    logging.info(f"disc has {len(disc_titles)} title(s)")
    for title_index in range(len(disc_titles)):
        title = disc_titles[title_index]
        size_human = title.get("size_human")
        file_name = title.get("file_output")
        output_path = f"/output/{disc_name}/"
        logging.info(
            f"getting title {title_index} with size of {size_human}.\n"
            + f"outputting to {output_path} as {file_name}"
        )
    os.makedirs(output_path, exist_ok=True)
    mm.mkv("all", output_path)
    logging.info("done reading file")


def is_drive_ready(drive_path: str) -> bool:
    fd = os.open(drive_path, os.O_RDONLY | os.O_NONBLOCK)
    try:
        drive_status = fcntl.ioctl(fd, CDROM_DRIVE_STATUS, 0)
        os.close(fd)
        return drive_status == CDS_DISC_OK
    finally:
        os.close(fd)


def main():
    # d = cdio.Device(driver_id=pycdio.DRIVER_UNKNOWN)
    drive_path = "/dev/sr0"
    # d.close()
    while True:
        while not is_drive_ready(drive_path):
            time.sleep(30)
        try:
            rip_with_makemkv(drive_path)
        except:
            logging.exception("failed to rip disc")
        pycdio.eject_media_drive(drive_path)

main()