import matplotlib.pyplot as plt
import numpy as np
import networkx as nx
import argparse
import os

parser = argparse.ArgumentParser(description="options for plotting")
parser.add_argument("--path",type=str,required=True,help="path of folder to analize")
args = parser.parse_args()

def makeHist(res):
    nclass = 5
    bins = np.arange(0.5,nclass + 0.53,1)
    hist = np.array([np.histogram(res[i,:],bins=bins,density=True)[0] for i in range(res.shape[0])])
    return hist

print("plotting time evolution...  ", end="")


labels=["S","I","R","D","Im"]
sims_dirs = [x for x in os.listdir(args.path) if x[0:3]=="sim"]
graphs_dirs = [x for x in os.listdir(args.path) if x[0:7]=="con_net"]
graphs = []
results = []
if len(graphs_dirs) <= 1:
    G = nx.read_graphml(os.path.join(args.path,"con_net.graphml"))
    G = nx.convert_node_labels_to_integers(G)
    graphs = [G for i in sims_dirs]
for i in range(len(sims_dirs)):
    res = np.loadtxt(os.path.join(args.path,"simulation_{0}.csv".format(i+1)),dtype=np.int8,delimiter=",")
    results.append(res)
    if len(graphs_dirs) > 1:
        G = nx.read_graphml(os.path.join(args.path,"con_net_{0}.graphml".format(i+1)))
        G = nx.convert_node_labels_to_integers(G)
        graphs.append(G)


hists = np.array([makeHist(res) for res in results])
results = np.array(results)
avgs = np.mean(hists,axis=0)
stds = np.std(hists,axis=0)
fig,axs = plt.subplots(ncols=1,nrows=2,figsize=(12,9),sharex=True)
for j in range(len(avgs[0])):
    axs[0].plot(avgs[:,j],label=labels[j],lw=1.5,c="C{0}".format(j))
    axs[0].fill_between(range(len(avgs[:,j])),avgs[:,j]+stds[:,j],avgs[:,j]-stds[:,j],facecolor="grey",alpha=0.5)
axs[0].legend(loc="upper right")
#plt.xlabel("Time")
axs[0].set_ylabel("Proportion")
axs[0].set_ylim(0,1)
axs[0].grid()
#plt.savefig(os.path.join(args.path,"evolution.png"),dpi=200)
print("done")


print("Plotting only infected ...",end="")
j = 1
axs[1].plot(avgs[:,j],label="Mean",lw=1.5)
axs[1].fill_between(range(len(avgs[:,j])),avgs[:,j]+stds[:,j],avgs[:,j]-stds[:,j],facecolor="grey",alpha=0.5)
for i in range(len(sims_dirs)):
    axs[1].plot(hists[i,:,j],label="iter {0}".format(i))
axs[1].legend(loc="upper right")
axs[1].set_xlabel("Time")
axs[1].set_ylabel("Proportion of infected")
axs[1].grid()
plt.savefig(os.path.join(args.path,"evolution.png"),dpi=200)
print("done")
print("calculating average distances... ",end="")
n = results[0].shape[1]
m = results[0].shape[0]
dists = np.zeros((len(graphs),n,n))
for k in range(len(graphs)):
    lengs = dict(nx.all_pairs_shortest_path_length(graphs[k]))
    for i in range(n):
        for j in range(i+1,n):
            dists[k,i,j] = lengs[i][j]
            dists[k,j,i] = dists[k,i,j]
print("done")
print("plotting average distances... ",end="")
avgDists = np.zeros(m)
stdDists = np.zeros(m)
for t in range(m):
    sucIndex = []
    infIndex = []
    vals = []
    for k in range(len(graphs)):
        sucIndex = [i for i in range(n) if results[k,t,i]==1]
        infIndex = [j for j in range(n) if results[k,t,j]==2]
        vals.extend([dists[k,i,j] for i in sucIndex for j in infIndex])
    if len(vals)>0:
        avgDists[t] = np.mean(vals)
        stdDists[t] = np.std(vals)
fig = plt.figure(figsize=(12,4))
plt.errorbar(range(m),avgDists,yerr=stdDists,ecolor= (0.1, 0.2, 0.5, 0.3))
plt.xlabel("time")
plt.ylabel("Average S-I distance")
plt.grid()
plt.savefig(os.path.join(args.path,"distance.png"))
print("done")
print("plotting infected neighbors... ",end="")
avgDists = np.zeros(m)
stdDists = np.zeros(m)
for t in range(m):
    neigDist = []
    for k in range(len(graphs)):
        sucIndex = [i for i in range(n) if results[k,t,i]==1]
        if len(sucIndex)>0:
            vals = np.zeros(len(sucIndex))
            for index,i in enumerate(sucIndex):
                vals[index] = len([j for j in graphs[k].neighbors(i) if results[k,t,j]==2])/len(list(graphs[k].neighbors(i)))
            neigDist.extend(vals)
        avgDists[t] = np.mean(neigDist)
        stdDists[t] = np.std(neigDist)
fig = plt.figure(figsize=(12,4))
plt.errorbar(range(m),avgDists,yerr=stdDists,ecolor= (0.1, 0.2, 0.5, 0.3))
plt.xlabel("time")
plt.ylabel("Average fraction of S-I Neighbors")
plt.grid()
plt.savefig(os.path.join(args.path,"neighbors.png"))
print("done")