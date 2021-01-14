import pandas as pd
import ftfy as ft
print("Reading data ... ",end="")
df = pd.read_csv("../data/conacyt.csv",header=0,encoding="latin-1")
print("Done")
# cleaning nationality encoding issue
print("Solving encoding ... ",end="")
#df["PAIS_NACIONALIDAD"] = [ft.fix_text(s) for s in df["PAIS_NACIONALIDAD"]]
df["PAIS_NACIONALIDAD"] = df["PAIS_NACIONALIDAD"].apply(ft.fix_text)
print("Done")
# selecting only true
print("Exporting clean data ... ",end="")
# CLASIFICACION_FINAL encodes 
df[df["CLASIFICACION_FINAL"]<=3].to_csv("../data/positive.csv",index=False,encoding="utf-8")
print("Done")