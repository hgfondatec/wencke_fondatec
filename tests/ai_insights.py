import json
import html as html_lib
import pandas as pd
import requests

from sqlalchemy import create_engine


# ============================================================
# 1. KONFIGURATION
# ============================================================

DB_USER = "sbs"
DB_PASSWORD = "qaqpav-xyxhi9-jeGmyv"
DB_HOST = "172.30.30.5"
DB_PORT = "5432"
DB_NAME = "wenke"


SCHEMA = "reporting_wencke"

TABLE_KPI = "gold_ai_kpi_monthly"
TABLE_CUSTOMER = "gold_ai_customer_drivers_monthly"
TABLE_PRODUCT = "gold_ai_product_drivers_monthly"

ANALYSE_MONAT = "2026-07-01"

TOP_CUSTOMERS_DB = 20
TOP_PRODUCTS_DB = 20

TOP_CUSTOMERS_LLM = 3
TOP_PRODUCTS_LLM = 3

# ============================================================
# OLLAMA
# ============================================================

OLLAMA_URL = "http://localhost:11434/api/generate"

# Erstmal 3B.
# Wenn alles sauber läuft, kannst du später auf qwen2.5:7b wechseln.
OLLAMA_MODEL = "qwen2.5:3b"

OLLAMA_TIMEOUT = 300


# ============================================================
# 2. HILFSFUNKTIONEN
# ============================================================

def safe_float(value):
    if pd.isna(value):
        return None
    return float(value)


def safe_string(value):
    if pd.isna(value):
        return None
    return str(value)


def round_value(value, digits=2):
    if value is None:
        return None
    return round(float(value), digits)


def pct_value(value):
    """
    Datenbank liefert Prozentwerte als Dezimalzahl:
    0.006 = 0.6 %

    Für das LLM rechnen wir bereits in echte Prozentwerte um.
    """
    if value is None:
        return None
    return round(float(value) * 100, 2)


def pp_value(value):
    """
    Margen-Delta:
    -0.0133 = -1.33 Prozentpunkte
    """
    if value is None:
        return None
    return round(float(value) * 100, 2)


def format_eur(value):
    if value is None:
        return "-"

    return (
        f"{value:,.2f} €"
        .replace(",", "X")
        .replace(".", ",")
        .replace("X", ".")
    )


def format_pct_decimal(value):
    """
    Für Werte aus dem ursprünglichen result-JSON,
    die noch als Dezimalwerte vorliegen.
    """
    if value is None:
        return "-"

    return f"{value * 100:.2f} %".replace(".", ",")


def format_pp_decimal(value):
    if value is None:
        return "-"

    return f"{value * 100:.2f} PP".replace(".", ",")


def format_number(value):
    if value is None:
        return "-"

    return (
        f"{value:,.0f}"
        .replace(",", ".")
    )


# ============================================================
# 3. DATENBANKVERBINDUNG
# ============================================================

print("")
print("============================================================")
print("DATENBANKVERBINDUNG")
print("============================================================")
print("")

engine = create_engine(
    f"postgresql+psycopg2://"
    f"{DB_USER}:{DB_PASSWORD}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)


# ============================================================
# 4. SQL-ABFRAGEN
# ============================================================

query_kpi = f"""
SELECT *
FROM {SCHEMA}.{TABLE_KPI}
WHERE monat = '{ANALYSE_MONAT}'
"""

query_customers = f"""
SELECT *
FROM {SCHEMA}.{TABLE_CUSTOMER}
WHERE monat = '{ANALYSE_MONAT}'
ORDER BY ABS(umsatz_delta) DESC
LIMIT {TOP_CUSTOMERS_DB}
"""

query_products = f"""
SELECT *
FROM {SCHEMA}.{TABLE_PRODUCT}
WHERE monat = '{ANALYSE_MONAT}'
ORDER BY ABS(umsatz_delta) DESC
LIMIT {TOP_PRODUCTS_DB}
"""


# ============================================================
# 5. DATEN LADEN
# ============================================================

print("Lade Daten aus PostgreSQL...")

df_kpi = pd.read_sql(
    query_kpi,
    engine
)

df_customers = pd.read_sql(
    query_customers,
    engine
)

df_products = pd.read_sql(
    query_products,
    engine
)

print("Daten erfolgreich geladen.")


# ============================================================
# 6. KPI-DATEN PRÜFEN
# ============================================================

if df_kpi.empty:

    engine.dispose()

    raise ValueError(
        f"Keine KPI-Daten für den Monat "
        f"{ANALYSE_MONAT} gefunden."
    )


# ============================================================
# 7. KOMPLETTES RESULT-JSON AUFBAUEN
# ============================================================

kpi = df_kpi.iloc[0]

result = {

    "period": safe_string(
        kpi["monat"]
    ),

    "revenue": {

        "current": safe_float(
            kpi["umsatz"]
        ),

        "previous": safe_float(
            kpi["umsatz_vormonat"]
        ),

        "delta": safe_float(
            kpi["umsatz_delta"]
        ),

        "delta_pct": safe_float(
            kpi["umsatz_delta_pct"]
        )
    },

    "quantity": {

        "current": safe_float(
            kpi["menge"]
        ),

        "previous": safe_float(
            kpi["menge_vormonat"]
        ),

        "delta": safe_float(
            kpi["menge_delta"]
        ),

        "delta_pct": safe_float(
            kpi["menge_delta_pct"]
        )
    },

    "gross_profit": {

        "current": safe_float(
            kpi["rohertrag"]
        ),

        "previous": safe_float(
            kpi["rohertrag_vormonat"]
        ),

        "delta": safe_float(
            kpi["rohertrag_delta"]
        ),

        "delta_pct": safe_float(
            kpi["rohertrag_delta_pct"]
        )
    },

    "margin": {

        "current": safe_float(
            kpi["marge"]
        ),

        "previous": safe_float(
            kpi["marge_vormonat"]
        ),

        "delta": safe_float(
            kpi["marge_delta"]
        )
    },

    "top_customer_drivers": [],

    "top_product_drivers": []
}


# ============================================================
# 8. KUNDENTREIBER
# ============================================================

for _, row in df_customers.iterrows():

    result["top_customer_drivers"].append({

        "customer": safe_string(
            row["bel_adr_nr"]
        ),

        "revenue": safe_float(
            row["umsatz"]
        ),

        "previous_revenue": safe_float(
            row["umsatz_vormonat"]
        ),

        "impact": safe_float(
            row["umsatz_delta"]
        ),

        "change_pct": safe_float(
            row["umsatz_delta_pct"]
        ),

        "quantity": safe_float(
            row["menge"]
        ),

        "previous_quantity": safe_float(
            row["menge_vormonat"]
        ),

        "quantity_delta": safe_float(
            row["menge_delta"]
        ),

        "gross_profit": safe_float(
            row["rohertrag"]
        ),

        "previous_gross_profit": safe_float(
            row["rohertrag_vormonat"]
        ),

        "gross_profit_delta": safe_float(
            row["rohertrag_delta"]
        ),

        "margin": safe_float(
            row["marge"]
        ),

        "previous_margin": safe_float(
            row["marge_vormonat"]
        ),

        "margin_delta": safe_float(
            row["marge_delta"]
        )
    })


# ============================================================
# 9. ARTIKELTREIBER
# ============================================================

for _, row in df_products.iterrows():

    result["top_product_drivers"].append({

        "product_id": safe_string(
            row["pos_artikel_nr"]
        ),

        "product": safe_string(
            row["pos_artikel_text"]
        ),

        "revenue": safe_float(
            row["umsatz"]
        ),

        "previous_revenue": safe_float(
            row["umsatz_vormonat"]
        ),

        "impact": safe_float(
            row["umsatz_delta"]
        ),

        "change_pct": safe_float(
            row["umsatz_delta_pct"]
        ),

        "quantity": safe_float(
            row["menge"]
        ),

        "previous_quantity": safe_float(
            row["menge_vormonat"]
        ),

        "quantity_delta": safe_float(
            row["menge_delta"]
        ),

        "gross_profit": safe_float(
            row["rohertrag"]
        ),

        "previous_gross_profit": safe_float(
            row["rohertrag_vormonat"]
        ),

        "gross_profit_delta": safe_float(
            row["rohertrag_delta"]
        ),

        "margin": safe_float(
            row["marge"]
        ),

        "previous_margin": safe_float(
            row["marge_vormonat"]
        ),

        "margin_delta": safe_float(
            row["marge_delta"]
        )
    })


# ============================================================
# 10. TREIBER SORTIEREN
# ============================================================

negative_customer_drivers = sorted(

    [
        x
        for x in result["top_customer_drivers"]
        if x["impact"] is not None
        and x["impact"] < 0
    ],

    key=lambda x: x["impact"]
)


positive_customer_drivers = sorted(

    [
        x
        for x in result["top_customer_drivers"]
        if x["impact"] is not None
        and x["impact"] > 0
    ],

    key=lambda x: x["impact"],

    reverse=True
)


negative_product_drivers = sorted(

    [
        x
        for x in result["top_product_drivers"]
        if x["impact"] is not None
        and x["impact"] < 0
    ],

    key=lambda x: x["impact"]
)


positive_product_drivers = sorted(

    [
        x
        for x in result["top_product_drivers"]
        if x["impact"] is not None
        and x["impact"] > 0
    ],

    key=lambda x: x["impact"],

    reverse=True
)


# ============================================================
# 11. REGELBASIERTE INSIGHTS
# ============================================================

rule_based_insights = []

if result["revenue"]["delta_pct"] is not None:

    value = result["revenue"]["delta_pct"]

    if value > 0:

        rule_based_insights.append(
            f"Der Umsatz ist gegenüber dem Vormonat "
            f"um {value * 100:.2f}% gestiegen."
        )

    elif value < 0:

        rule_based_insights.append(
            f"Der Umsatz ist gegenüber dem Vormonat "
            f"um {abs(value) * 100:.2f}% gesunken."
        )


if result["gross_profit"]["delta_pct"] is not None:

    value = result["gross_profit"]["delta_pct"]

    if value > 0:

        rule_based_insights.append(
            f"Der Rohertrag ist gegenüber dem Vormonat "
            f"um {value * 100:.2f}% gestiegen."
        )

    elif value < 0:

        rule_based_insights.append(
            f"Der Rohertrag ist gegenüber dem Vormonat "
            f"um {abs(value) * 100:.2f}% gesunken."
        )


if result["margin"]["delta"] is not None:

    value = result["margin"]["delta"]

    if value > 0:

        rule_based_insights.append(
            f"Die Marge ist gegenüber dem Vormonat "
            f"um {value * 100:.2f} Prozentpunkte gestiegen."
        )

    elif value < 0:

        rule_based_insights.append(
            f"Die Marge ist gegenüber dem Vormonat "
            f"um {abs(value) * 100:.2f} Prozentpunkte gesunken."
        )


result["rule_based_insights"] = rule_based_insights


# ============================================================
# 12. KOMPLETTES JSON SPEICHERN
# ============================================================

raw_json_file = (
    f"ai_insights_raw_{ANALYSE_MONAT}.json"
)

with open(
    raw_json_file,
    "w",
    encoding="utf-8"
) as file:

    json.dump(
        result,
        file,
        indent=4,
        ensure_ascii=False
    )


print("")
print(
    f"Komplettes Analyse-JSON gespeichert: "
    f"{raw_json_file}"
)


# ============================================================
# 13. REDUZIERTES LLM-JSON ERSTELLEN
# ============================================================
#
# EXTREM WICHTIG:
#
# Ollama bekommt NICHT mehr das gesamte Result-JSON.
#
# Python entscheidet vorher exakt,
# welche Zahlen relevant sind.
#
# Prozentwerte werden bereits in echte Prozentwerte umgerechnet.
#
# Beispiel:
#
# vorher:
# 0.006093
#
# jetzt:
# 0.61
#
# Dadurch muss das LLM praktisch nichts mehr berechnen.
# ============================================================

llm_input = {

    "period": ANALYSE_MONAT,

    "company_kpis": {

        "revenue_current_eur": round_value(
            result["revenue"]["current"]
        ),

        "revenue_previous_eur": round_value(
            result["revenue"]["previous"]
        ),

        "revenue_change_eur": round_value(
            result["revenue"]["delta"]
        ),

        "revenue_change_pct": pct_value(
            result["revenue"]["delta_pct"]
        ),

        "gross_profit_current_eur": round_value(
            result["gross_profit"]["current"]
        ),

        "gross_profit_previous_eur": round_value(
            result["gross_profit"]["previous"]
        ),

        "gross_profit_change_eur": round_value(
            result["gross_profit"]["delta"]
        ),

        "gross_profit_change_pct": pct_value(
            result["gross_profit"]["delta_pct"]
        ),

        "margin_current_pct": pct_value(
            result["margin"]["current"]
        ),

        "margin_previous_pct": pct_value(
            result["margin"]["previous"]
        ),

        "margin_change_percentage_points": pp_value(
            result["margin"]["delta"]
        ),

        "quantity_current": round_value(
            result["quantity"]["current"]
        ),

        "quantity_previous": round_value(
            result["quantity"]["previous"]
        ),

        "quantity_change": round_value(
            result["quantity"]["delta"]
        ),

        "quantity_change_pct": pct_value(
            result["quantity"]["delta_pct"]
        )
    },

    "top_negative_customers": [],

    "top_positive_customers": [],

    "top_negative_products": [],

    "top_positive_products": []
}


# ============================================================
# 14. TOP KUNDEN FÜR LLM
# ============================================================

for customer in negative_customer_drivers[:TOP_CUSTOMERS_LLM]:

    llm_input["top_negative_customers"].append({

        "customer_id": customer["customer"],

        "revenue_change_eur": round_value(
            customer["impact"]
        ),

        "revenue_change_pct": pct_value(
            customer["change_pct"]
        ),

        "quantity_current": round_value(
            customer["quantity"]
        ),

        "quantity_previous": round_value(
            customer["previous_quantity"]
        ),

        "quantity_change": round_value(
            customer["quantity_delta"]
        )
    })


for customer in positive_customer_drivers[:TOP_CUSTOMERS_LLM]:

    llm_input["top_positive_customers"].append({

        "customer_id": customer["customer"],

        "revenue_change_eur": round_value(
            customer["impact"]
        ),

        "revenue_change_pct": pct_value(
            customer["change_pct"]
        ),

        "quantity_current": round_value(
            customer["quantity"]
        ),

        "quantity_previous": round_value(
            customer["previous_quantity"]
        ),

        "quantity_change": round_value(
            customer["quantity_delta"]
        )
    })


# ============================================================
# 15. TOP ARTIKEL FÜR LLM
# ============================================================

for product in negative_product_drivers[:TOP_PRODUCTS_LLM]:

    llm_input["top_negative_products"].append({

        "product_id": product["product_id"],

        "product_name": product["product"],

        "revenue_change_eur": round_value(
            product["impact"]
        ),

        "revenue_change_pct": pct_value(
            product["change_pct"]
        ),

        "quantity_current": round_value(
            product["quantity"]
        ),

        "quantity_previous": round_value(
            product["previous_quantity"]
        ),

        "quantity_change": round_value(
            product["quantity_delta"]
        )
    })


for product in positive_product_drivers[:TOP_PRODUCTS_LLM]:

    llm_input["top_positive_products"].append({

        "product_id": product["product_id"],

        "product_name": product["product"],

        "revenue_change_eur": round_value(
            product["impact"]
        ),

        "revenue_change_pct": pct_value(
            product["change_pct"]
        ),

        "quantity_current": round_value(
            product["quantity"]
        ),

        "quantity_previous": round_value(
            product["previous_quantity"]
        ),

        "quantity_change": round_value(
            product["quantity_delta"]
        )
    })


# ============================================================
# 16. LLM INPUT SPEICHERN
# ============================================================

llm_json_file = (
    f"ai_insights_llm_input_{ANALYSE_MONAT}.json"
)

with open(
    llm_json_file,
    "w",
    encoding="utf-8"
) as file:

    json.dump(
        llm_input,
        file,
        indent=4,
        ensure_ascii=False
    )


print(
    f"Reduziertes LLM-JSON gespeichert: "
    f"{llm_json_file}"
)


print("")
print("============================================================")
print("DATEN, DIE TATSÄCHLICH AN OLLAMA GESENDET WERDEN")
print("============================================================")
print("")

print(
    json.dumps(
        llm_input,
        indent=4,
        ensure_ascii=False
    )
)


# ============================================================
# 17. OLLAMA PROMPT
# ============================================================
#
# WICHTIG:
#
# Keine Rechenaufgaben mehr.
# Keine großen verschachtelten Daten.
# Keine einzelnen Rohertragswerte von Artikeln.
#
# Ollama soll ausschließlich FORMULIEREN.
# ============================================================

prompt = f"""
Du bist ein Senior Business Analyst.

Du erhältst bereits vollständig berechnete und geprüfte Kennzahlen.

Deine einzige Aufgabe ist es, diese Fakten verständlich für die Geschäftsführung zu formulieren.

SEHR WICHTIGE REGELN:

1. Führe KEINE eigenen Berechnungen durch.

2. Erfinde KEINE Zahlen.

3. Verwende ausschließlich Zahlen, die exakt in den gelieferten Daten stehen.

4. Die Werte unter "company_kpis" sind die EINZIGEN Gesamtwerte des Unternehmens.

5. Werte unter "top_negative_customers" und "top_positive_customers"
sind ausschließlich einzelne Kundentreiber.

6. Werte unter "top_negative_products" und "top_positive_products"
sind ausschließlich einzelne Artikeltreiber.

7. Kunden- oder Artikelwerte dürfen NIEMALS als Gesamtwerte bezeichnet werden.

8. "gross_profit" bedeutet immer ROHERTRAG.
Verwende niemals das Wort Gewinn.

9. Werte mit der Endung "_pct" sind bereits Prozentwerte.
Beispiel:
0.61 bedeutet 0,61 Prozent.
NICHT 61 Prozent.

10. "margin_change_percentage_points" ist bereits eine Veränderung
in Prozentpunkten.
Beispiel:
-1.33 bedeutet minus 1,33 Prozentpunkte.

11. "revenue_change_eur" bedeutet Umsatzveränderung gegenüber dem Vormonat.
Verwende dafür nicht den Begriff "Umsatzverlust".

12. Erfinde keine Gründe wie:
Marketing,
Kundenzufriedenheit,
Produktqualität,
Lieferprobleme,
Wettbewerb,
Vertriebsprobleme
oder ähnliche Ursachen.

13. Mengenveränderungen dürfen nur als beobachtbarer Zusammenhang beschrieben werden.

Beispiel erlaubt:

"Der Umsatzrückgang geht mit einer deutlich geringeren Absatzmenge einher."

Beispiel NICHT erlaubt:

"Der Umsatz ist aufgrund mangelnder Kundenzufriedenheit gesunken."

14. Wenn eine tatsächliche Ursache nicht eindeutig aus den Daten ableitbar ist,
schreibe:

"Die konkrete Ursache ist aus den vorliegenden Daten nicht eindeutig ableitbar."

15. Verwende deutsche Zahlenformate und runde sinnvoll.

Beispiel:

7211067.39
=
7.211.067,39 EUR

0.61
=
0,61 %

-1.33
=
-1,33 Prozentpunkte


ERSTELLE DIE ANTWORT IN FOLGENDER STRUKTUR:


MANAGEMENT SUMMARY

Maximal vier kurze Sätze.

Nenne zuerst:
- Umsatzentwicklung
- Rohertragsentwicklung
- Margenentwicklung


UMSATZENTWICKLUNG

Nenne exakt:
- aktuellen Umsatz
- Umsatz Vormonat
- Veränderung in EUR
- Veränderung in Prozent


ROHERTRAG UND MARGE

Nenne:
- aktuellen Rohertrag
- Rohertrag Vormonat
- Veränderung des Rohertrags
- aktuelle Marge
- Marge Vormonat
- Margenveränderung in Prozentpunkten


WICHTIGSTE KUNDENTREIBER

Nenne die gelieferten negativen und positiven Kundentreiber.

Verwende ausschließlich deren revenue_change_eur.


WICHTIGSTE ARTIKELTREIBER

Nenne die gelieferten negativen und positiven Artikeltreiber.

Verwende ausschließlich deren revenue_change_eur.


MENGENBEOBACHTUNGEN

Prüfe, ob auffällige Umsatzveränderungen gleichzeitig mit deutlichen
Mengenveränderungen auftreten.

Beschreibe nur diesen Zusammenhang.


NÄCHSTE ANALYSE

Nenne maximal drei sinnvolle Analyseschritte.

Keine erfundenen Ursachen.


DATEN:

{json.dumps(llm_input, ensure_ascii=False, indent=2)}
"""


# ============================================================
# 18. OLLAMA AUFRUFEN
# ============================================================

payload = {

    "model": OLLAMA_MODEL,

    "prompt": prompt,

    "stream": False,

    "options": {

        # Niedrige Temperatur:
        # weniger kreative / erfundene Antworten
        "temperature": 0.0,

        # Reproduzierbarere Ausgabe
        "seed": 42
    }
}


print("")
print("============================================================")
print(f"OLLAMA WIRD AUFGERUFEN | MODELL: {OLLAMA_MODEL}")
print("============================================================")
print("")


management_summary = None


try:

    response = requests.post(

        OLLAMA_URL,

        json=payload,

        timeout=OLLAMA_TIMEOUT
    )

    response.raise_for_status()

    ollama_response = response.json()

    management_summary = ollama_response.get(
        "response",
        ""
    ).strip()


    print("")
    print("============================================================")
    print("KI MANAGEMENT ANALYSE")
    print("============================================================")
    print("")

    print(
        management_summary
    )


except requests.exceptions.ConnectionError:

    print(
        "FEHLER: Ollama konnte nicht erreicht werden."
    )

    print(
        f"Prüfe Ollama unter: {OLLAMA_URL}"
    )


except requests.exceptions.Timeout:

    print(
        "FEHLER: Ollama hat nicht innerhalb des "
        "Timeouts geantwortet."
    )


except requests.exceptions.RequestException as exc:

    print(
        f"FEHLER beim Ollama-Aufruf: {exc}"
    )


# ============================================================
# 19. KI TEXT ALS TXT SPEICHERN
# ============================================================

txt_file = (
    f"ai_management_summary_{ANALYSE_MONAT}.txt"
)

with open(
    txt_file,
    "w",
    encoding="utf-8"
) as file:

    if management_summary:

        file.write(
            management_summary
        )

    else:

        file.write(
            "Keine KI-Analyse verfügbar."
        )


print("")
print(
    f"KI-Text gespeichert: "
    f"{txt_file}"
)


# ============================================================
# 20. FINALES JSON SPEICHERN
# ============================================================

result["llm_input"] = llm_input

result["ai_management_summary"] = (
    management_summary
)


final_json_file = (
    f"ai_insights_final_{ANALYSE_MONAT}.json"
)


with open(
    final_json_file,
    "w",
    encoding="utf-8"
) as file:

    json.dump(
        result,
        file,
        indent=4,
        ensure_ascii=False
    )


print(
    f"Finales JSON gespeichert: "
    f"{final_json_file}"
)


# ============================================================
# 21. HTML REPORT DATEN
# ============================================================

revenue = result["revenue"]

gross_profit = result["gross_profit"]

margin = result["margin"]

quantity = result["quantity"]


html_negative_customers = (
    negative_customer_drivers[:5]
)

html_positive_customers = (
    positive_customer_drivers[:5]
)

html_negative_products = (
    negative_product_drivers[:5]
)

html_positive_products = (
    positive_product_drivers[:5]
)


# ============================================================
# 22. HTML TABELLEN
# ============================================================

def build_customer_rows(customers):

    rows = ""

    for customer in customers:

        impact_class = (
            "positive"
            if customer["impact"] >= 0
            else "negative"
        )

        rows += f"""
        <tr>
            <td>{html_lib.escape(str(customer["customer"]))}</td>
            <td>{format_eur(customer["revenue"])}</td>
            <td>{format_eur(customer["previous_revenue"])}</td>
            <td class="{impact_class}">
                {format_eur(customer["impact"])}
            </td>
            <td>{format_pct_decimal(customer["change_pct"])}</td>
        </tr>
        """

    return rows


def build_product_rows(products):

    rows = ""

    for product in products:

        impact_class = (
            "positive"
            if product["impact"] >= 0
            else "negative"
        )

        rows += f"""
        <tr>
            <td>{html_lib.escape(str(product["product_id"]))}</td>
            <td>{html_lib.escape(str(product["product"]))}</td>
            <td>{format_eur(product["revenue"])}</td>
            <td>{format_eur(product["previous_revenue"])}</td>
            <td class="{impact_class}">
                {format_eur(product["impact"])}
            </td>
            <td>{format_pct_decimal(product["change_pct"])}</td>
        </tr>
        """

    return rows


# ============================================================
# 23. KI TEXT FÜR HTML SICHER MACHEN
# ============================================================

if management_summary:

    management_summary_html = (
        html_lib.escape(
            management_summary
        )
        .replace(
            "\n",
            "<br>"
        )
    )

else:

    management_summary_html = (
        "Keine KI-Analyse verfügbar."
    )


# ============================================================
# 24. HTML REPORT
# ============================================================

html_report = f"""
<!DOCTYPE html>
<html lang="de">

<head>

<meta charset="UTF-8">

<meta name="viewport"
content="width=device-width, initial-scale=1.0">

<title>
AI Business Insights | {ANALYSE_MONAT}
</title>

<style>

body {{
    margin: 0;
    padding: 0;
    background: #f5f6f8;
    font-family: Arial, Helvetica, sans-serif;
    color: #1f2937;
}}

.container {{
    max-width: 1450px;
    margin: 0 auto;
    padding: 40px;
}}

.header {{
    background: #111827;
    color: white;
    padding: 35px;
    border-radius: 14px;
    margin-bottom: 25px;
}}

.header h1 {{
    margin: 0;
    font-size: 32px;
}}

.header p {{
    margin-top: 8px;
    margin-bottom: 0;
    color: #d1d5db;
}}

.kpi-grid {{
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 20px;
    margin-bottom: 25px;
}}

.kpi-card {{
    background: white;
    padding: 24px;
    border-radius: 14px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}}

.kpi-title {{
    font-size: 14px;
    color: #6b7280;
    margin-bottom: 10px;
}}

.kpi-value {{
    font-size: 27px;
    font-weight: bold;
}}

.kpi-previous {{
    margin-top: 10px;
    margin-bottom: 8px;
    font-size: 13px;
    color: #6b7280;
}}

.positive {{
    color: #047857;
    font-weight: 600;
}}

.negative {{
    color: #b91c1c;
    font-weight: 600;
}}

.section {{
    background: white;
    padding: 30px;
    border-radius: 14px;
    margin-bottom: 25px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}}

.section h2 {{
    margin-top: 0;
    font-size: 21px;
}}

.ai-text {{
    line-height: 1.7;
    font-size: 15px;
}}

.two-column {{
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 25px;
}}

table {{
    width: 100%;
    border-collapse: collapse;
    margin-top: 15px;
}}

th {{
    text-align: left;
    padding: 12px;
    background: #f3f4f6;
    font-size: 13px;
}}

td {{
    padding: 12px;
    border-bottom: 1px solid #e5e7eb;
    font-size: 14px;
}}

.badge-negative {{
    display: inline-block;
    background: #fee2e2;
    color: #991b1b;
    padding: 5px 10px;
    border-radius: 20px;
    font-size: 12px;
    margin-right: 8px;
}}

.badge-positive {{
    display: inline-block;
    background: #d1fae5;
    color: #065f46;
    padding: 5px 10px;
    border-radius: 20px;
    font-size: 12px;
    margin-right: 8px;
}}

.info {{
    background: #eff6ff;
    border-left: 4px solid #2563eb;
    padding: 15px 18px;
    margin-bottom: 25px;
    border-radius: 8px;
    font-size: 13px;
}}

.footer {{
    color: #9ca3af;
    font-size: 12px;
    text-align: center;
    margin-top: 30px;
}}

@media (max-width: 950px) {{

    .kpi-grid {{
        grid-template-columns: 1fr 1fr;
    }}

    .two-column {{
        grid-template-columns: 1fr;
    }}

}}

</style>

</head>

<body>

<div class="container">

<div class="header">

<h1>
AI Business Insights
</h1>

<p>
Automatisierte Management-Analyse |
{ANALYSE_MONAT} |
{OLLAMA_MODEL}
</p>

</div>


<div class="info">

Die KPI-Werte werden deterministisch in PostgreSQL/dbt berechnet.
Das lokale KI-Modell formuliert ausschließlich die bereits
vorbereiteten Analyseergebnisse.

</div>


<div class="kpi-grid">


<div class="kpi-card">

<div class="kpi-title">
Umsatz
</div>

<div class="kpi-value">
{format_eur(revenue["current"])}
</div>

<div class="kpi-previous">
Vormonat:
{format_eur(revenue["previous"])}
</div>

<div class="{
    'positive'
    if revenue['delta'] is not None
    and revenue['delta'] >= 0
    else 'negative'
}">

{format_eur(revenue["delta"])}

|

{format_pct_decimal(revenue["delta_pct"])}

</div>

</div>


<div class="kpi-card">

<div class="kpi-title">
Rohertrag
</div>

<div class="kpi-value">
{format_eur(gross_profit["current"])}
</div>

<div class="kpi-previous">
Vormonat:
{format_eur(gross_profit["previous"])}
</div>

<div class="{
    'positive'
    if gross_profit['delta'] is not None
    and gross_profit['delta'] >= 0
    else 'negative'
}">

{format_eur(gross_profit["delta"])}

|

{format_pct_decimal(gross_profit["delta_pct"])}

</div>

</div>


<div class="kpi-card">

<div class="kpi-title">
Marge
</div>

<div class="kpi-value">
{format_pct_decimal(margin["current"])}
</div>

<div class="kpi-previous">
Vormonat:
{format_pct_decimal(margin["previous"])}
</div>

<div class="{
    'positive'
    if margin['delta'] is not None
    and margin['delta'] >= 0
    else 'negative'
}">

{format_pp_decimal(margin["delta"])}

</div>

</div>


<div class="kpi-card">

<div class="kpi-title">
Menge
</div>

<div class="kpi-value">
{format_number(quantity["current"])}
</div>

<div class="kpi-previous">
Vormonat:
{format_number(quantity["previous"])}
</div>

<div class="{
    'positive'
    if quantity['delta'] is not None
    and quantity['delta'] >= 0
    else 'negative'
}">

{format_number(quantity["delta"])}

|

{format_pct_decimal(quantity["delta_pct"])}

</div>

</div>


</div>


<div class="section">

<h2>
KI Management Analyse
</h2>

<div class="ai-text">

{management_summary_html}

</div>

</div>


<div class="two-column">


<div class="section">

<h2>

<span class="badge-negative">
Negative Treiber
</span>

Kunden

</h2>

<table>

<tr>

<th>Kunde</th>
<th>Umsatz</th>
<th>Vormonat</th>
<th>Delta</th>
<th>%</th>

</tr>

{build_customer_rows(html_negative_customers)}

</table>

</div>


<div class="section">

<h2>

<span class="badge-positive">
Positive Treiber
</span>

Kunden

</h2>

<table>

<tr>

<th>Kunde</th>
<th>Umsatz</th>
<th>Vormonat</th>
<th>Delta</th>
<th>%</th>

</tr>

{build_customer_rows(html_positive_customers)}

</table>

</div>


</div>


<div class="two-column">


<div class="section">

<h2>

<span class="badge-negative">
Negative Treiber
</span>

Artikel

</h2>

<table>

<tr>

<th>Artikel</th>
<th>Bezeichnung</th>
<th>Umsatz</th>
<th>Vormonat</th>
<th>Delta</th>
<th>%</th>

</tr>

{build_product_rows(html_negative_products)}

</table>

</div>


<div class="section">

<h2>

<span class="badge-positive">
Positive Treiber
</span>

Artikel

</h2>

<table>

<tr>

<th>Artikel</th>
<th>Bezeichnung</th>
<th>Umsatz</th>
<th>Vormonat</th>
<th>Delta</th>
<th>%</th>

</tr>

{build_product_rows(html_positive_products)}

</table>

</div>


</div>


<div class="footer">

AI Business Insights |
Lokal analysiert mit Ollama / {OLLAMA_MODEL}

</div>


</div>

</body>

</html>
"""


# ============================================================
# 25. HTML SPEICHERN
# ============================================================

html_file = (
    f"ai_business_insights_{ANALYSE_MONAT}.html"
)


with open(
    html_file,
    "w",
    encoding="utf-8"
) as file:

    file.write(
        html_report
    )


print("")
print("============================================================")
print("HTML REPORT ERSTELLT")
print("============================================================")
print("")

print(
    f"HTML Report gespeichert unter: "
    f"{html_file}"
)


# ============================================================
# 26. DATENBANKVERBINDUNG SCHLIESSEN
# ============================================================

engine.dispose()


# ============================================================
# 27. ABSCHLUSS
# ============================================================

print("")
print("============================================================")
print("FERTIG")
print("============================================================")
print("")

print(
    f"Modell: {OLLAMA_MODEL}"
)

print(
    f"Rohdaten: {raw_json_file}"
)

print(
    f"LLM Input: {llm_json_file}"
)

print(
    f"KI Text: {txt_file}"
)

print(
    f"Finales JSON: {final_json_file}"
)

print(
    f"HTML: {html_file}"
)

print("")