function [out , varargout]  = tkmeans(Y,k,alpha,varargin)
%tkmeans computes trimmed k-means
%
%<a href="matlab: docsearch('tkmeans')">Link to the help function</a>
%
%   tkmeans(Y, k, alpha) partitions the points in the n-by-v data matrix Y
%   into k clusters.  This partition minimizes the trimmed sum, over all
%   clusters, of the within-cluster sums of point-to-cluster-centroid
%   distances.  Rows of Y correspond to points, columns correspond to
%   variables. tkmeans returns inside structure out an n-by-1 vector IDX
%   containing the cluster indices of each point.  By default, tkmeans uses
%   (squared) Euclidean distances.
%
%
%  Required input arguments:
%
%     Y: Data matrix containining n observations on v variables
%        Rows of Y represent observations, and columns
%        represent variables.
%        Missing values (NaN's) and infinite values (Inf's) are allowed,
%        since observations (rows) with missing or infinite values will
%        automatically be excluded from the computations.
%     k: scalar which specifies the number of groups
% alpha: global trimming level. alpha is a scalar between 0 and 0.5. If
%        alpha=0 tkmeans reduces to kmeans
%
%  Optional input arguments:
%
%       nsamp : Number of subsamples which will be extracted to find the
%               partition. If nsamp=0 all subsets will be extracted.
%               They will be (n choose k).
%               Remark: if the number of all possible subset is <300 the
%               default is to extract all subsets, otherwise just 300
%    refsteps : scalar defining number of refining iterations in each
%               subsample (default = 15).
%     reftol  : scalar. Default value of tolerance for the refining steps
%               The default value is 1e-14;
%     weights : a dummy scalar, specifying whether cluster weights
%               (1) shall be considered in the concentration and
%               assignment steps. Remark: if weights=1 in the assignment
%               step to the squared Euclidean distance of unit i to group j
%               log n_j is substracted. The default is no cluster weights
%       plots : Scalar or structure.
%               If plots = 1, a plot with the classification is
%               shown on the screen.
%        msg  : scalar which controls whether to display or not messages
%               on the screen If msg==1 (default) messages are displayed
%               on the screen about estimated time to compute the estimator
%               else no message is displayed on the screen
%      nocheck: Scalar. If nocheck is equal to 1 no check is performed on
%               matrix Y. 
%               As default nocheck=0. 
%        nomes: Scalar. If nomes is equal to 1 no message about estimated
%               time to compute tkemans is displayed, else if nomes is
%               equal to 0 (default), a message about estimated time is
%               displayed.
%       Ysave : scalar that is set to 1 to request that the input matrix Y
%               is saved into the output structure out. Default is 0, i.e.
%               no saving is done.
%
%
%       Remark: The user should only give the input arguments that have to
%               change their default value. The name of the input arguments
%               needs to be followed by their value. The order of the input
%               arguments is of no importance.
%
%
%  Output:
%
%  The output consists of a structure 'out' containing the following fields:
%
%            out.idx  : n-by-1 vector containing assignment of each unit to
%                       each of the k groups. Cluster names are integer
%                       numbers from 1 to k, 0 indicates trimmed
%                       observations.
%            out.muopt: k-by-v matrix containing cluster centroid locations.
%                       Robust estimate of final centroids of the groups
%              out.bs : k-by-1 vector containing the units forming initial
%                       subset associated with muopt.
%               out.D : n-by-k matrix containing squared Euclidean
%                       distances from each point to every centroid.
%            out.siz  : matrix of size k-by-3
%                       1st col = sequence from 0 to k
%                       2nd col = number of observations in each cluster
%                       3rd col = percentage of observations in each cluster
%                       Remark: 0 denotes unassigned units
%        out.weights  : numerical vector of length k, containing the
%                       weights of each cluster. If input option weights=1
%                       out.weights=(1/k, ...., 1/k) else if input option
%                       weights <> 1 out.weights=(n1/n, ..., nk/n)
%               out.h : scalar. Number of observations that have determined the
%                       centroids (number of untrimmed units).
%             out.obj : scalar. Value of the objective function which is minimized 
%                       (value of the best returned solution).
%              out.Y  : original data matrix Y. The field is present if option
%                       Ysave is set to 1.
%
% See also kmeans, tclust
%
% References:
%
% Garcia-Escudero, L.A.; Gordaliza, A.; Matran, C. and Mayo-Iscar, A.
% (2008), "A General Trimming Approach to Robust Cluster Analysis". Annals
% of Statistics, Vol.36, 1324-1345. Technical Report available at
% www.eio.uva.es/inves/grupos/representaciones/trTCLUST.pdf
%
%
% Copyright 2008-2014.
% Written by FSDA team
%
% DETAILS. This iterative algorithm initializes k clusters randomly and
% performs "concentration steps" in order to improve the current cluster
% assignment. The number of maximum concentration steps to be performed is
% given by input parameter refsteps. For approximately obtaining the global
% optimum, the system is initialized nsamp times and concentration steps
% are performed until convergence or refsteps is reached. When processing
% more complex data sets higher values of nsamp and refsteps have to be
% specified (obviously implying extra computation time). However, if more
% then half of the iterations do not converge, a warning message is issued,
% indicating that nsamp has to be increased.
%
%
%<a href="matlab: docsearch('tkmeans')">Link to the help function</a>
% Last modified 08-Dec-2013

% Examples:

%
%{
    % Trimmed k-means using geyser data
    % 3 groups and trimming level of 3%
    Y=load('geyser2.txt');
    out=tkmeans(Y,3,0.03,'plots',1)
%}


%{
    % Trimmed k-means using geyser data
    % option weights =1
    Y=load('geyser2.txt');
    out=tkmeans(Y,3,0.03,'plots',1,'weights',1)
%}

%{
    % Trimmed k-means using M5data
    % Weights =1
    Y=load('M5data.txt');
    out=tkmeans(Y(:,1:2),3,0,'plots',1)
    out=tkmeans(Y(:,1:2),5,0.1,'plots',1)

%}

%{
    % Trimmed k-means using structured noise
    % The data have been generated using the following R instructions
    %    set.seed (0)
    %    v <- runif (100, -2 * pi, 2 * pi)
    %    noise <- cbind (100 + 25 * sin (v), 10 + 5 * v)
    %
    %
    %    x <- rbind (
    %        rmvnorm (360, c (0.0,  0), matrix (c (1,  0,  0, 1), ncol = 2)),
    %        rmvnorm (540, c (5.0, 10), matrix (c (6, -2, -2, 6), ncol = 2)),
    %        noise)


    %
    Y=load('structurednoise.txt');
    out=tkmeans(Y(:,1:2),2,0.1,'plots',1)
    out=tkmeans(Y(:,1:2),5,0.15,'plots',1)

%}

%{
    % Trimmed k-means using mixture100 data
    % The data have been generated using the following R instructions
    %     set.seed (100)
    %     mixt <- rbind (rmvnorm (360, c (  0,  0), matrix (c (1,  0,  0,  1), ncol = 2)),
    %                rmvnorm (540, c (  5, 10), matrix (c (6, -2, -2,  6), ncol = 2)),
    %                rmvnorm (100, c (2.5,  5), matrix (c (50, 0,  0, 50), ncol = 2)))


    % 
    Y=load('mixture100.txt');
    out=tkmeans(Y(:,1:2),3,0,'plots',1)
    out=tkmeans(Y(:,1:2),2,0.05,'plots',1)

%}


%% Input parameters checking
nnargin=nargin;
vvarargin=varargin;
Y = chkinputM(Y,nnargin,vvarargin);
[n, v]=size(Y);


%% User options


% If the number of all possible subsets is <10000 the default is to extract
% all subsets otherwise just 10000.
% Notice that we use bc, a fast version of nchoosek. One may also use the
% approximation floor(exp(gammaln(n+1)-gammaln(n-p+1)-gammaln(p+1))+0.5)
ncomb=bc(n,k);
nsampdef=min(300,ncomb);
refstepsdef=15;
reftoldef=1e-14;

% Default
if nargin<3;
    alpha=0.05;
end

% Fix alpha equal to the trimming size
% h = number of observations which is used to compute the centroids

if alpha<0 || alpha>0.5
    error('alpha must a scalar in the interval [0 0.5]')
end


h=n-fix(n*alpha);

options=struct('nsamp',nsampdef,'plots',0,'nocheck',0,'nomes',0,...
    'msg',1,'Ysave',0,'refsteps',refstepsdef,'weights',0,...
    'reftol',reftoldef);

UserOptions=varargin(1:2:length(varargin));
if ~isempty(UserOptions)
    
    
    % Check if number of supplied options is valid
    if length(varargin) ~= 2*length(UserOptions)
        error('Error:: number of supplied options is invalid. Probably values for some parameters are missing.');
    end
    
    % Check if all the specified optional arguments were present
    % in structure options
    % Remark: the nocheck option has already been dealt by routine
    % chkinputR
    inpchk=isfield(options,UserOptions);
    WrongOptions=UserOptions(inpchk==0);
    if ~isempty(WrongOptions)
        disp(strcat('Non existent user option found->', char(WrongOptions{:})))
        error('Error:: in total %d non-existent user options found.', length(WrongOptions));
    end
end

if nargin > 2
    
    % Write in structure 'options' the options chosen by the user
    for i=1:2:length(varargin);
        options.(varargin{i})=varargin{i+1};
    end
    
    % And check if the optional user parameters are reasonable.
    
    % Check number of subsamples to extract
    if options.nsamp>ncomb;
        disp('Number of subsets to extract greater than (n k). It is set to (n k)');
        options.nsamp=0;
    elseif  options.nsamp<0;
        error('Number of subsets to extract must be 0 (all) or a positive number');
    end
end

% Default values for the optional
% parameters are set inside structure 'options'

plots=options.plots;        % Plot of the resulting classification 
nsamp=options.nsamp;        % Number of subsets to extract
weights=options.weights;    % Specify if assignment must take into account the size of the groups

refsteps=options.refsteps;
reftol=options.reftol;

%Initialize the objective function (trimmed variance) by a
%large  value
vopt=1e+10;

msg=options.msg;            % Scalar which controls the messages displayed on the screen

nomes=options.nomes;        % if options.nomes==1 no message about estimated time to compute tkmeans is displayed


%% Combinatorial part to extract the subsamples
[C,nselected] = subsets(nsamp,n,k,ncomb,msg);
% Store the indices in varargout
if nargout==2
    varargout={C};
end

% D = matrix of distances for each unit from each cluster
% rows of D are associated to units
% Columns of D are associated to clusters
D=zeros(n,k);


obj=1e+14;

% initialise and start timer.
tsampling = ceil(min(nselected/100 , 1000));
time=zeros(tsampling,1);

% noconv = scalar linked to the number of times in which there was no
% convergence
noconv=0;

%% Core of trimmed k means function
for i=1:nselected
    if i <= tsampling, tic; end
    
    % extract a subset of size v
    index = C(i,:);
    
    cini=Y(index,:);
    
    iter=0;
    mudiff=1e+15;
    
    while ( (mudiff > reftol) && (iter < refsteps) )
        iter = iter + 1;
        
        % Compute the distance of each unit to each centroid
        % D(i,j) contains the Euclidean distance of unit i from cluster j
        % D(i,:) (vector 1 x k) contains the distance of unit i
        % from the k clusters
        % D(:,j) (vector n x 1) contains the distance of the n units from
        % cluster j
        for j=1:k
            D(:,j)=sum(bsxfun(@minus,Y,cini(j,:)).^2,2);
        end
        
        if weights == 1 && iter>1
            siz=tabulate(Ytri(:,end));
            D=bsxfun(@minus,D,log(siz(:,1)'));
        end
        
        % dist = n x 1 vector which contains the distance of each unit to
        % the closest cluster
        % ind = n x 1 vector containing the assignments
        [dist,ind]=min(D,[],2);
        
        % Sort the n-distances
        [~,qq]=sort(dist);
        
        % qq = vector of size h which contains the indexes associated with the smallest n(1-alpha)
        % distances
        qq=qq(1:h);
        
        % Ytri = matrix with n(1-alpha) rows associated with the units
        % which have the smallest n(1-alpha) distances from the centers
        Ytri=[Y(qq,:),ind(qq)];
        
        
        % Calculus of matrix cini containing the new k centroids
        for j=1:k
            ni=sum(Ytri(:,v+1)==j);
            if ni>1,
                cini(j,:)=mean(Ytri(Ytri(:,v+1)==j,1:v));
            end
        end
        
        
        oldobj=obj;
        
        % Value of the objective function
        % Mean of the squared distances of each unit to the closest centroid
        obj= sum(sum((Ytri(:,1:v)-cini(Ytri(:,v+1),:)).^2,2)  /h);
        
        mudiff =oldobj-obj;
        %         disp(['Iteration ' num2str(t)])
        %         disp([oldobj-obj])
        
        if iter==refsteps;
            noconv=noconv+1;
        end
        
    end
    
    % Store the centroids and the value of the objective function
    if obj<=vopt,
        % vopt = value of the objective function in correspondence of the
        % best centroids
        vopt=obj;
        % muopt = matrix containing best centroids
        muopt=cini;
        % store the indexes of the initial centroids which gave rise to the
        % optimal solution
        bs=index;
    end
    
    
    if ~nomes
        if i <= tsampling
            
            % sampling time until step tsampling
            time(i)=toc;
        elseif i==tsampling+1
            % stop sampling and print the estimated time
            if msg==1
                fprintf('Total estimated time to complete trimmed k means: %5.2f seconds \n', nselected*median(time));
            end
        end
    end
    
end

if noconv/nselected>0.1;
    disp('------------------------------')
    disp(['Warning: Number of subsets without convergence equal to ' num2str(100*noconv/nselected) '%'])
end

%% Store quantities in out structure

% Store robust estimate of final centroids of the groups
out.muopt=muopt;

% Store units forming initial subset which gave rise to the optimal
% solution
out.bs=bs;


for j=1:k
    D(:,j)=sum(bsxfun(@minus,Y,muopt(j,:)).^2,2);
end

if weights == 1
    siz=tabulate(Ytri(:,end));
    
    D=bsxfun(@minus,D,log(siz(:,1)'));
end


% dist = n x 1 vector which contains the distance of each unit to
% the closest cluster
% ind = n x 1 vector containing the assignments
[dist,idx]=min(D,[],2);


% Sort the n-distances
[~,qq]=sort(dist);

% qq = vector of size h which contains the indexes associated with the smallest n(1-alpha)
% distances
qq=qq(1:h);

% noasig = units not used for the centroids = unassigned units
noasig=setdiff(1:n,qq);
idx(noasig)=0;

% Store the assignments in matrix out
% Unassigned units have an assignment equal to 0
out.idx=idx;

% siz = matrix of size k x 3,
% 1st col = sequence from 0 to k
% 2nd col = number of observations in each cluster
% 3rd col = percentage of observations in each cluster
siz=tabulate(out.idx);
out.siz=siz;


if weights ~= 1
    out.weights=ones(1,k)/k;
else
    out.weights=(siz')/n;
end

% Store the number of observations that have not been trimmed in the
% computation of the centroids
out.h=h;

% Store n x k distance matrix (squared distance of each row from each cluster)
out.D=D;

% Store value of the objective function (trimmed variance) /2
out.obj=vopt/2;


if options.Ysave
    % Store original data matrix
    out.Y=Y;
end


%% Create plots
% Plot the groups in the scatter plot matrix
% if plots==1;
%     
%    id=cellstr(num2str(idx));
%    id(idx==0)=cellstr('Trimmed observations');
%    spmplot(Y,id);
%     
% end
% Plot the groups in the scatter plot matrix
if plots==1;
    if v==1
        
        histFS(Y,length(Y),idx)
    elseif v==2
        colors = 'brcmykgbrcmykgbrcmykg';
        figure
        hold('on')
        for j=1:k
           idxj=idx==j;
           if sum(idxj)>0
            plot(Y(idxj,1),Y(idxj,2),'o','color',colors(j));
            ellipse(muopt(j,:),cov(Y(idxj,:)))
           end
        end
        if alpha>0
            idxj=idx==0;
            plot(Y(idxj,1),Y(idxj,2),'x','color','k');
        end
        
        axis equal
    else
        
        id=cellstr(num2str(idx));
        id(idx==0)=cellstr('Trimmed observations');
        spmplot(Y,id);
    end
end

end






