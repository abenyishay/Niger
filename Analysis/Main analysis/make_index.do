/***********************************************
*MEAN EFFECTS INDEX
*This ado file creates an index using inverse covariance weighting, a la Anderson (2008).
*The command is 'make_index' and it takes three arguments in a required sequence 
*	(1) The suffix for the name of the new index
*	(2) The treatment weight (used in the covariance matrix)
*	(3) The name of the local macro with the variables for the weighted index.
	
*For example: 
*	make_index recid_direct wgt `recid_direct' 
	
*produces the index index_recid_direct using the weight "wgt" and the index vars in local
*macro `recid_direct'
***********************************************/


clear all
set more off

capture program drop make_index
program make_index
version 11.1
    syntax anything [if]
    gettoken newname anything: anything
    gettoken wgt anything: anything
    local Xvars `anything'
	marksample touse
	quietly: cor `Xvars' [aweight=`wgt']
	matrix S = r(C)
  	mata: icwxmata(("`Xvars'"),"`wgt'", "index")
	rename index index_`newname'
end
 
mata:
	function icwxmata(xvars, wgts, indexname)
	{
		st_view(X=0,.,tokens(xvars))
		st_view(wgt=.,.,wgts)
		nr = rows(X)
		nc = cols(X)
		wgtst = wgt/sum(wgt)
		wgtstdM = J(1,nc,1) # wgtst
		wgtdmeans = colsum(X:*wgtstdM)
		wgtdmeandevs = (X - J(nr,1,1) # wgtdmeans)
		wgtdstds = sqrt(colsum(wgt:*(wgtdmeandevs:*wgtdmeandevs)):/(sum(wgt)-1))
		Xs = wgtdmeandevs:/(J(nr,1,1) # wgtdstds)
		invS = invsym(st_matrix("S"))
		ivec = J(nc,1,1)
		indexout_sc = (invsym(ivec'*invS*ivec)*ivec'*invS*Xs')'
		indexout = (indexout_sc - J(nr,1,1)# mean(indexout_sc))/sqrt(variance(indexout_sc))
		st_addvar("float",indexname)
		st_store(.,indexname,indexout)
	}
end



