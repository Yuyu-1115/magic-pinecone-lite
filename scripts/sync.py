import asyncio
import logging
from database.db_connect import db_session
from internal.course_fetcher import sync_courses_to_db
from internal.scholarship_fetcher import sync_scholarships_to_db

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("sync_script")

async def main():
    logger.info("Starting database sync via CLI...")
    try:
        with db_session() as db:
            logger.info("Syncing courses...")
            await sync_courses_to_db(db)
            logger.info("Syncing scholarships...")
            await sync_scholarships_to_db(db)
        logger.info("Sync complete.")
    except Exception as e:
        logger.error(f"Sync failed: {e}")
        raise e

if __name__ == "__main__":
    asyncio.run(main())
