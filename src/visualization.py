import matplotlib.pyplot as plt
import numpy as np
import networkx as nx
import argparse
import os

parser = argparse.ArgumentParser(description="options for plotting")
parser.add_argument("--path",type=str,required=True,help="path of file to analize")
args = parser.parse_args()

def evolutionPlot(res,ax,labels=["S","I","R","D"],**kwargs):
    nclass = len(np.unique(res))
    hist = np.array([np.histogram(res[i,:],bins=nclass)[0] for i in range(res.shape[0])])
    for j in range(nclass):
        ax.plot(hist[:,j],label=labels[j],**kwargs)
    ax.legend(loc="upper right")

res = np.loadtxt(os.path.join(args.path,"simulation.csv"),dtype=np.int8,delimiter=",")
G = nx.read_graphml(os.path.join(args.path,"network.graphml"))
G = nx.convert_node_labels_to_integers(G)
print("plotting time evolution...  ", end="")
fig = plt.figure(figsize=(6,4))
evolutionPlot(res,plt.gca(),lw=2)
plt.xlabel("time")
plt.ylabel("frequency")
plt.ylim(0,res.shape[1])
plt.grid()
plt.savefig(os.path.join(args.path,"evolution.png"),dpi=200)
print("done")
print("calculating average distances... ",end="")
n = res.shape[1]
lengs = dict(nx.all_pairs_shortest_path_length(G))
dists = np.zeros((n,n))
for i in range(n):
    for j in range(i+1,n):
        dists[i,j] = lengs[i][j]
        dists[j,i] = dists[i,j]
print("done")
print("plotting average distances... ",end="")
avgDists = np.zeros(res.shape[0])
stdDists = np.zeros(res.shape[0])
for t in range(res.shape[0]):
    vals = []
    sucIndex = [i for i in range(n) if res[t,i]==1]
    infIndex = [j for j in range(n) if res[t,j]==2]
    if len(sucIndex)>0 and len(infIndex)>0:
        vals = [dists[i,j] for i in sucIndex for j in infIndex]
        avgDists[t] = np.mean(vals)
        stdDists[t] = np.std(vals)
fig = plt.figure()
plt.errorbar(range(res.shape[0]),avgDists,yerr=stdDists,ecolor= (0.1, 0.2, 0.5, 0.3))
plt.xlabel("time")
plt.ylabel("Average S-I distance")
plt.grid()
plt.savefig(os.path.join(args.path,"distance.png"))
print("done")