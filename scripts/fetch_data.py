import asyncio
import logging
import httpx
import os
import json
import re
from bs4 import BeautifulSoup
import xml.etree.ElementTree as ET
from urllib.parse import urlparse, parse_qs
from datetime import datetime, timezone

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("fetch_data")

COURSE_REMOTE_URL = 'https://cis.ncu.edu.tw/Course/main/support/course.xml'
COURSE_HEADER = {
    'Accept-Language': 'zh-TW',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}
SCHOLARSHIP_URL = 'https://cis.ncu.edu.tw/Scholarship/'

async def fetch_colleges_with_departments():
    colleges = []
    async with httpx.AsyncClient(verify=False) as client:
        response = await client.get('https://cis.ncu.edu.tw/Course/main/query/byUnion', headers=COURSE_HEADER)
        response.raise_for_status()

        soup = BeautifulSoup(response.content, 'html.parser')
        tables = soup.select('#byUnion_table table')
        for i, table in enumerate(tables):
            tr1 = table.find('tr')
            if not tr1: 
                continue
            th = tr1.find('th')
            raw_college_name = th.get_text(strip=True) if th else f"College {i}"
            college_name = re.sub(r'\(.*?\)', '', raw_college_name).strip()

            departments = []
            tr2 = table.find_all('tr')[1] if len(table.find_all('tr')) > 1 else None
            if tr2:
                anchors = tr2.select('td ul li a')
                for anchor in anchors:
                    href = anchor.get('href', '')
                    parsed_url = urlparse(href)
                    qs = parse_qs(parsed_url.query)
                    department_id = qs.get('dept', [''])[0]
                    department_name = re.sub(r'\(\d+\)$', '', anchor.get_text(strip=True))

                    departments.append({
                        "name": department_name,
                        "code": department_id
                    })

            colleges.append({
                "name": college_name,
                "departments": departments
            })
    return colleges

async def fetch_course_bases(department_code: str, department_name: str, college_name: str):
    courses = []
    async with httpx.AsyncClient(verify=False) as client:
        response = await client.get(COURSE_REMOTE_URL, headers=COURSE_HEADER, params={"id": department_code})
        if response.status_code != 200:
            return courses

        try:
            root = ET.fromstring(response.content)
        except Exception as e:
            logger.warning(f"Failed to parse XML for department {department_code}: {e}")
            return courses

        for course_elem in root.findall('.//Course'):
            attr = course_elem.attrib
            class_no = attr.get('ClassNo', '')
            class_no_fmt = f"{class_no[:6]}-{class_no[6:]}" if len(class_no) > 6 else class_no

            teacher_str = attr.get('Teacher', '')
            teachers = [t.strip() for t in teacher_str.split(',') if t.strip()]

            times_str = attr.get('ClassTime', '')
            class_times = []
            if times_str:
                for t in times_str.split(','):
                    t_clean = t.strip()
                    if len(t_clean) == 2:
                        class_times.append(f"{t_clean[0]}-{t_clean[1]}")

            serial_no = attr.get('SerialNo', '').zfill(5) if attr.get('SerialNo') else ""
            detail_url = f"https://cis.ncu.edu.tw/Course/main/support/courseDetail.html?crs={serial_no}" if serial_no else ""

            courses.append({
                "serial_no": serial_no,
                "class_no": class_no_fmt,
                "title": attr.get('Title', ''),
                "credit": float(attr.get('credit', 0) or 0),
                "password_card": attr.get('passwordCard', '') or None,
                "teachers": teachers,
                "class_times": class_times,
                "limit_cnt": int(attr.get('limitCnt', 0) or 0),
                "admit_cnt": int(attr.get('admitCnt', 0) or 0),
                "wait_cnt": int(attr.get('waitCnt', 0) or 0),
                "college_name": college_name,
                "department_name": department_name,
                "course_type": "UNKNOWN",
                "detail_url": detail_url
            })
    return courses

async def fetch_all_course_extras():
    course_extras = {}
    page_no = 1
    async with httpx.AsyncClient(verify=False) as client:
        while True:
            response = await client.get(
                'https://cis.ncu.edu.tw/Course/main/query/byKeywords',
                headers=COURSE_HEADER,
                params={
                    'd-49489-p': page_no,
                    'query': 'true'
                }
            )
            if response.status_code != 200:
                break
            
            soup = BeautifulSoup(response.content, 'html.parser')
            trs = soup.select('#item tbody tr')
            if not trs:
                break
            
            for tr in trs:
                td1 = tr.select_one('td:nth-child(1)')
                serial_no = td1.contents[0].strip() if td1 and td1.contents else ""
                
                td6 = tr.select_one('td:nth-child(6)')
                raw_type = td6.get_text(strip=True) if td6 else ""
                course_type = "REQUIRED" if raw_type == "必修" else "ELECTIVE" if raw_type == "選修" else "UNKNOWN"
                
                if serial_no:
                    course_extras[serial_no.zfill(5)] = course_type

            # Check next page
            pagelinks = soup.select('.pagelinks > *')
            if pagelinks and pagelinks[-1].name == 'a':
                page_no += 1
            else:
                break
    return course_extras

async def fetch_scholarship_data():
    results = []
    async with httpx.AsyncClient(verify=False) as client:
        response = await client.get(SCHOLARSHIP_URL)
        response.raise_for_status()
        response.encoding = 'utf-8'
        
        soup = BeautifulSoup(response.text, 'html.parser')
        table = soup.find('table', class_='news_list')
        if not table:
            logger.warning("Could not find table.news_list on the scholarship page.")
            return results

        rows = table.find_all('tr')
        for idx, row in enumerate(rows[1:]):
            cols = row.find_all('td')
            if len(cols) < 4:
                continue

            category = cols[1].get_text(strip=True)
            title = cols[2].get_text(strip=True)

            content_summary_dict = {}
            text = cols[3].get_text(separator='\n', strip=True).replace('\n下載', ' 下載')
            for line in text.split('\n'):
                line = line.strip()
                if not line:
                    continue
                if ' :' in line:
                    parts = line.split(' :', 1)
                elif '：' in line:
                    parts = line.split('：', 1)
                elif ':' in line:
                    parts = line.split(':', 1)
                else:
                    parts = ["", line]

                label = parts[0].strip()
                value = parts[1].strip()
                content_summary_dict[label] = value

            download_link = None
            link_tag = cols[3].find('a')
            if link_tag and link_tag.get('href'):
                href = link_tag.get('href')
                if href.startswith('..'):
                    href = href.replace('..', 'https://cis.ncu.edu.tw', 1)
                elif href.startswith('/'):
                    href = f"https://cis.ncu.edu.tw{href}"
                download_link = href

            results.append({
                "id": idx + 1,
                "category": category,
                "title": title,
                "content_summary": content_summary_dict,
                "download_link": download_link
            })
    return results

async def main():
    logger.info("Starting synchronization scrape process...")
    os.makedirs("dist", exist_ok=True)
    
    # 1. Fetch Scholarship Data
    logger.info("Fetching scholarships and part-time jobs...")
    try:
        scholarships = await fetch_scholarship_data()
        scholarship_payload = {
            "last_updated": datetime.now(timezone.utc).isoformat(),
            "scholarships": scholarships
        }
        with open("dist/scholarships.json", "w", encoding="utf-8") as f:
            json.dump(scholarship_payload, f, ensure_ascii=False, indent=2)
        logger.info(f"Successfully saved {len(scholarships)} scholarship records.")
    except Exception as e:
        logger.error(f"Error fetching scholarships: {e}")

    # 2. Fetch Course Data
    logger.info("Fetching colleges and departments...")
    try:
        colleges = await fetch_colleges_with_departments()
        logger.info(f"Fetched {len(colleges)} colleges.")
        
        # Gather all course bases
        all_courses = []
        for c in colleges:
            for d in c['departments']:
                dept_courses = await fetch_course_bases(d['code'], d['name'], c['name'])
                all_courses.extend(dept_courses)
                
        logger.info(f"Fetched {len(all_courses)} total raw course records.")

        # Deduplicate
        unique_courses = {}
        for course in all_courses:
            serial = course.get('serial_no')
            if serial:
                unique_courses[serial] = course
        
        # Merge course extras
        logger.info("Fetching course extras...")
        extras = await fetch_all_course_extras()
        for serial, c_type in extras.items():
            if serial in unique_courses:
                unique_courses[serial]['course_type'] = c_type

        course_list = list(unique_courses.values())
        course_payload = {
            "last_updated": datetime.now(timezone.utc).isoformat(),
            "courses": course_list
        }
        with open("dist/courses.json", "w", encoding="utf-8") as f:
            json.dump(course_payload, f, ensure_ascii=False, indent=2)
        logger.info(f"Successfully saved {len(course_list)} course records.")
        
    except Exception as e:
        logger.error(f"Error fetching course data: {e}")

if __name__ == "__main__":
    asyncio.run(main())
