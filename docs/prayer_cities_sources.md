# Egyptian prayer location catalog

Updated: 2026-11-16.

`assets/data/prayer_cities.json` now includes 70 Egyptian locations: the
27 governorate capitals and 43 additional cities/towns. This is a curated
offline catalog, not an exhaustive list of every Egyptian city or village.
Each entry identifies a populated place, not the centroid of a governorate.
The existing Cairo/Alexandria entries and all international entries are retained.

## Sources and attribution

New city coordinates are derived from [GeoNames](https://www.geonames.org/),
available under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Arabic display names and English transliterations are adapted for the app.
Coordinates are rounded to at most six decimal places.

- [Governorates and capitals](https://www.geonames.org/EG/administrative-division-egypt.html)
- [Egypt populated places, first page](https://www.geonames.org/search.html?country=EG&startRow=0)
- [Egypt populated places, second page](https://www.geonames.org/search.html?country=EG&startRow=50)
- [Banha](https://www.geonames.org/359280/banha.html)
- [Beni Suef, Minya, Mahalla and Kharga](https://www.geonames.org/search.html?country=EG&startRow=0)
- [Sharm El Sheikh](https://www.geonames.org/349340/sharm-el-sheikh.html)
- [New Cairo](https://www.geonames.org/7799991/new-cairo.html)
- [Dahab](https://www.geonames.org/358245/dahab.html)
- [Siwa town](https://www.geonames.org/advanced-search.html?q=Egypt&startRow=300)

All Egyptian entries use the existing `egyptian` calculation method default
and the IANA `Africa/Cairo` time zone. The app's existing user overrides apply.
GeoNames supplies geographic data, not approved prayer timetables.

## Governorate coverage

| Governorate | Capital entry ID |
|---|---|
| Cairo | `cairo` |
| Alexandria | `alexandria` |
| Giza | `giza` |
| Qalyubia | `banha` |
| Gharbia | `tanta` |
| Dakahlia | `mansoura` |
| Sharqia | `zagazig` |
| Beheira | `damanhur` |
| Kafr El Sheikh | `kafr_el_sheikh` |
| Monufia | `shebin_el_kom` |
| Damietta | `damietta` |
| Port Said | `port_said` |
| Ismailia | `ismailia` |
| Suez | `suez` |
| Fayoum | `fayoum` |
| Beni Suef | `beni_suef` |
| Minya | `minya` |
| Asyut | `asyut` |
| Sohag | `sohag` |
| Qena | `qena` |
| Luxor | `luxor` |
| Aswan | `aswan` |
| Red Sea | `hurghada` |
| Matruh | `marsa_matruh` |
| North Sinai | `arish` |
| South Sinai | `el_tor` |
| New Valley | `kharga` |
