import argparse
import ftfy as ft
import os
import pandas as pd
from sqlalchemy import create_engine
parser = argparse.ArgumentParser(description="correct encoding issue in DGE csvs")
parser.add_argument("--file",help="File to clean",type=str,required=True)
parser.add_argument("--db",help="Data base to save table. Ignored if --csv option is used",type=str,default="covidmx")
parser.add_argument("--csv",help="Save as csv instead of writing to DB",action="store_true")
args = parser.parse_args()
print("Reading data ... ",end="")
df = pd.read_csv(args.file,header=0,encoding="latin-1")
print("Done")
# cleaning nationality encoding issue
print("Solving encoding ... ",end="")
#df["PAIS_NACIONALIDAD"] = [ft.fix_text(s) for s in df["PAIS_NACIONALIDAD"]]
df["PAIS_NACIONALIDAD"] = df["PAIS_NACIONALIDAD"].apply(ft.fix_text)
print("Done")
# selecting only true
print("Exporting clean data ... ",end="")
basefile,extension = os.path.splitext(args.file)
if args.csv:
    df.to_csv(os.path.join(os.path.dirname(args.file),"full_registries.csv"),index=False,encoding="utf-8")
    # CLASIFICACION_FINAL encodes if they had covid or not
    df[df["CLASIFICACION_FINAL"]<=3].to_csv(os.path.join(os.path.dirname(args.file),"positive_registries.csv"),index=False,encoding="utf-8")
    print("Done")
else:
    engine = create_engine(f"postgresql:///{args.db}")
    df.to_sql("full_registries",engine,if_exists="replace")
