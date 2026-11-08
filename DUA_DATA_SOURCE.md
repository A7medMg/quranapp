# Dua and adhkar data sources

The offline library contains 1,533 Arabic records across 171 source category IDs, grouped into 97 Arabic situation labels. It contains 1,176 distinct texts overall and 1,010 distinct texts in the dua list after removing diacritics, tatweel, and whitespace and normalizing common letter variants. The dua list exposes 1,282 records; the adhkar list 359. One hundred and eight morning, evening, sleep, and other invocations appear in both lists because they are both supplications and remembrances.

- 906 entries with nonempty Arabic text come from [islamicapi/masnun-dua](https://github.com/islamicapi/masnun-dua), with its Arabic category and situation mappings. Empty-text records are omitted.
- 367 entries come from [sehalhussain/Hadith-Dua-assets](https://github.com/sehalhussain/Hadith-Dua-assets), including its Hisnul Muslim Arabic dua and adhkar data.
- 186 additional distinct entries come from [SiteQ8/duaarepo](https://github.com/SiteQ8/duaarepo). Only records with a Quran or hadith citation are included; narration-only records and duplicate texts are omitted.
- 74 additional unique texts come from [AhmedElTabarani/100-duaa-from-the-book-and-authentic-sunnah](https://github.com/AhmedElTabarani/100-duaa-from-the-book-and-authentic-sunnah). Quran and hadith references are retained and duplicate text is merged into the existing adhkar record where applicable.

The Masnun Dua project describes its dataset as free for use and asks that source texts remain intact. Hadith-Dua-assets permits use, adaptation, and distribution; attribution is appreciated. SiteQ8/duaarepo and the 100-dua collection are MIT licensed; their license texts ship in `assets/files/siteq8_dua_mit_license.txt` and `assets/files/100_duaa_mit_license.txt`.

Source references are displayed on each entry. The upstream 100-dua README notes that some hadith diacritics may contain errors; the app displays those texts as supplied and does not independently grade narrations. Explanatory benefits are not imported.