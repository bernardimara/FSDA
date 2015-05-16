function out = publishFS(file)
% publishFS('Score.m')
% fullPathToScript = locateFile(file);
% if isempty(fullPathToScript)
%     error('FSDA:publishFS:WrongFile','SourceNotFound');
% end

FileWithFullPath=which(file);
[pathstr,name,ext]=fileparts(FileWithFullPath);

if ~strcmp('.m',ext)
    error('FSDA:publishFS:WrongFileExt','Input file must have m extension')
end

if isempty(pathstr)
    error('FSDA:publishFS:WrongFile','SourceNotFound');
end

filename=FileWithFullPath;
% f = fopen(filename);

fileID = fopen(char(filename), 'r+');


% Insert the file into fstring
fstring=fscanf(fileID,'%c');

%% Add title
beforetitl=['<!DOCTYPE HTML> \r'  ...
    '<html itemscope="" xmlns="http://www.w3.org/1999/xhtml">\r' ...
    '<head>\r' ...
    '<title>\r'];
aftertitle='</title>';
titl=sprintf([beforetitl    name  aftertitle]);

%% Add purpose of the file (what is in the second row of .m file)
beforemetacontent=['<meta content="refpage" name="chunktype">\r' ...
    '<meta content="function:' name '" itemprop="refentity" name="refentity">\r'...
    '<meta content="text/javascript" http-equiv="Content-Script-Type">\r'...
    '<meta content="fcn" itemprop="pagetype" name="toctype">\r'...
    '<meta content="ref/function" itemprop="infotype" name="infotype" />\r'...
    '<meta content="'];
[startIndex] = regexp(fstring,'%');
% startIndex(2)-3 because there is also the carriage return
purpose=fstring(startIndex(1)+1:startIndex(2)-3);
aftermetacontent=['." itemprop="description" name="description" />\r'...
    '<script src="includesFS/jquery-latest.js" type="text/javascript"></script>\r'...
    '<script src="includesFS/l10n.js" type="text/javascript"></script>\r'...
    '<script src="includesFS/docscripts.js" type="text/javascript"></script>\r'...
    '<script src="includesFS/mw.toc.js" type="text/javascript"></script>\r'...
    '<script src="includesFS/mw.imagescaling.js" type="text/javascript"></script>\r'...
    '<script src="includesFS/mw.imageanimation.js" type="text/javascript"></script>\r'...
    '<link href="includes/product/css/reset.css" rel="stylesheet" type="text/css">\r'...
    '<link href="includes/product/css/960.css" rel="stylesheet" type="text/css">\r'...
    '<link href="includes/product/css/site5.css" rel="stylesheet" type="text/css">\r'...
    '<link href="includes/product/css/doc_center.css" rel="stylesheet" type="text/css">\r'...
    '<link href="includes/product/css/doc_center_installed.css" rel="stylesheet" type="text/css">\r'...
    '<link href="includes/product/css/doc_center_print.css" media="print" rel="stylesheet" type="text/css">\r'...
    '</head>\r'...
    '<body>\r'];
metacontent=sprintf([beforemetacontent purpose aftermetacontent]);

%% CONTAINER + SINTAX SECTION
sitecont=sprintf(['<div class="site_container site_toc_opened">\r'...
    '<div class="page_container">\r'...
    '<div class="content_frame">\r'...
    '<div id="content_container" class="content_container">\r'...
    '<section id="doc_center_content">\r'...
    '<div class="function_ref">\r'...
    '<div itemprop="content">\r'...
    '<h1 itemprop="title">'  name '</h1>\r'...
    '<div class="doc_topic_desc">\r'...
    '<div class="purpose_container">\r'...
    '<p itemprop="purpose">\r'...
    purpose '\r'...
    '</p>\r'...
    '<div class="switch">\r'...
    '<a id="expandAllPage" href="javascript:void(0);">\r'...
    'expand all in page</a></div>\r'...
    '</div>\r'...
    '</div>\r'...
    '</div>\r'...
    '<div class="ref_sect">\r'...
    '<h2 id="syntax">Syntax</h2>\r'...
    '<div class="syntax_signature">\r'...
    '<div class="syntax_signature_module">\r'...
    '<ul>\r']);

% Now find the number of required input
% arguments and if there are varargin
% and the number of required output
% arguments
% Find the string containing output arguments
%outargs= [out1, out2, out3]
[startIndex] = regexp(fstring,'[');
[endIndex] = regexp(fstring,']');
outargs=fstring(startIndex(1):endIndex(1));
% Find number of output arguments
% nargout = number of commas in string  outargs= [out1, out2, out3] +1
[commasOut] = regexp(outargs,',');
nargout=length(commasOut)+1;
% Find number of compulasory input arguments
% nargin = number of commas in string  functionname(inp1,inp2,inp3, ...)
[startIndex] = regexp(fstring,'(');
[endIndex] = regexp(fstring,')');
% inputargs =  (inp1,inp2,inp3, ...)
inputargs=fstring(startIndex(1):endIndex(1));
% Check if inputargs contains the string varargin
[optargs1]=regexp(inputargs,'varargin');
[commasIn] = regexp(inputargs,',');
if isempty(optargs1)
    sintax=cell(nargout,1);
    sintax{1}=[outargs(2:commasOut(1)-1) '=' name inputargs];
    j=2;
    nREQargin=length(commasIn)+1; % nREQargin = number of required input args
else
    % In this case there is also Name Value line
    sintax=cell(nargout+1,1);
    sintax{1}=[outargs(2:commasOut(1)-1) '=' name inputargs(1:optargs1-2) ')'];
    sintax{2}=[outargs(2:commasOut(1)-1) '=' name inputargs(1:optargs1-2) ',Name,Value)'];
    j=3;
    nREQargin=length(commasIn); % nREQargin = number of required input args
end



if nargout>1
    for i=2:nargout
        if i<nargout
            sintax{j}=[outargs(1:commasOut(i)-1) ']=' name '(___)'];
        else
            sintax{j}=[outargs '=' name '(___)'];
        end
        j=j+1;
    end
end

sintaxhtml='';

for j=1:length(sintax)
    sintaxhtml= [sintaxhtml '<li><code class="synopsis">'  sintax{j} '</code>' ...
        '<span class="syntax_example">'...
        '<a class="intrnllnk" href="' name '.html#ex' num2str(j) '">' ...
        'example</a></span></li>\r'];
end
sintaxhtml=sprintf(sintaxhtml);

%  										<li><code class="synopsis">idx = kmeans(X,k)</code>
%  										<span class="syntax_example">
%  										<a class="intrnllnk" href="kmeans.html#ex1">
%  										example</a></span></li>


sintaxclose=sprintf(['</ul>\r'...
    '</div>\r'...
    '</div>\r'...
    '</div>\r']);


%% DESCRIPTION SECTION

inidescription=sprintf(['	<div class="ref_sect" itemprop="content">\r'...
    '							<h2 id="description">Description</h2>\r'...
    '							<div class="descriptions">\r'...
    '								<div class="description_module">\r']);

descriptionhtml='';

for j=1:length(sintax)
    
    descriptionini=sprintf(['<div class="description_element">\r'...
        '	<p class="syntax_example">\r'...
        '	<a class="intrnllnk" href="' name '.html#ex'  num2str(j) '">\r'...
        '	example</a></p>\r'...
        '	<p><span itemprop="syntax"><code>\r']);
    
    %For each element of input and output argument a hypertext link is added
    sintaxj=sintax{j};
    % Locate in expression [out1,out2,...]=namefunc(inp1,inp2,...) the
    % position of equal sign
    [startIndex] = regexp(sintaxj,'=');
    outs=sintaxj(1:startIndex-1);
    
    
    commaspos=regexp(outs,',');
    if isempty(commaspos);
        noutel=1;
    else
        noutel=length(commaspos)+1;
    end
    if j==length(sintax)
        % Write in cell listargouts the list of output arguments
        listargouts=cell(noutel,1);
    end
    outstring='';
    if noutel>1
        for i=1:noutel
            if i==1
                outi=['[' outs(2:commaspos(i))];
                outstring=[outstring sprintf(['[' '<a class="intrnllnk" href="#outputarg_' outi(2:end-1) '"><code>' outi(2:end-1) '</code></a>,\r'])];
                if j==length(sintax)
                    listargouts{i}=outi(2:end-1);
                end
            elseif i==noutel
                outi=outs(commaspos(i-1)+1:end);
                outstring=[outstring sprintf(['<a class="intrnllnk" href="#outputarg_' outi(1:end-1) '"><code>' outi(1:end-1) '</code></a>]\r'])];
                if j==length(sintax)
                    listargouts{i}=outi(1:end-1);
                end
            else
                outi=outs(commaspos(i-1)+1:commaspos(i));
                outstring=[outstring sprintf(['<a class="intrnllnk" href="#outputarg_' outi(1:end-1) '"><code>' outi(1:end-1) '</code></a>,\r'])];
                if j==length(sintax)
                    listargouts{i}=outi(1:end-1);
                end
            end
            
        end
    else
        outi=outs;
        outstring=sprintf(['<a class="intrnllnk" href="#outputarg_' outi '"><code>' outi '</code></a>\r']);
        if j==length(sintax)
            listargouts{i}=outi;
        end
    end
    
    % Locate in  expression [out1,out2,...]=namefunc(inp1,inp2,...) the
    % position of open parenthesis sign
    [startIndex] = regexp(sintaxj,'(');
    inps=sintaxj(startIndex+1:end-1);
    commaspos=regexp(inps,',');
    if isempty(commaspos);
        ninpel=1;
    else
        ninpel=length(commaspos)+1;
    end
    inpstring='';
    if ninpel>1
        for i=1:ninpel
            if i==1
                inpi=inps(1:commaspos(i));
            elseif i==ninpel
                inpi=[inps(commaspos(i-1)+1:end) ' '];
            else
                inpi=inps(commaspos(i-1)+1:commaspos(i));
            end
            disp(inpi)
            if (strcmp(inpi,'Name,') + strcmp(inpi,'Value'))>0
                inpstring=[inpstring sprintf('<a class="intrnllnk" href="#namevaluepairarguments"><code>Name, Value</code></a>\r')]; %#ok<*AGROW>
                break
            elseif  strcmp(inpi,'___') ==1
                inpstring=[inpstring sprintf([inpi '\r'])]; %#ok<*AGROW>
            else
                inpstring=[inpstring sprintf(['<a class="intrnllnk" href="#inputarg_' inpi(1:end-1) '"><code>' inpi(1:end-1) '</code></a>,\r'])]; %#ok<*AGROW>
            end
        end
    else
        inpi=inps;
        if strcmp(inpi,'___') ==1
            inpstring=sprintf([inpi '\r']);
        else
            inpstring=sprintf(['<a class="intrnllnk" href="#inputarg_' inpi '"><code>' inpi '</code></a>\r']);
        end
    end
    
    description=[outstring '=' name '(' inpstring ')'];
    %     description=sprintf(['<a class="intrnllnk" href="#outputarg_idx"><code>idx</code></a>\r'...
    %         '	= kmeans(<a class="intrnllnk" href="#inputarg_X"><code>X</code></a>\r'...
    %         '	,\r'...
    %         '   <a class="intrnllnk" href="#inputarg_k"><code>k</code></a>)\r']);
    
    descriptionend=sprintf(['   </code></span>\r'...
        '	TOWRITE </p>\r'...
        '</div>']);
    description=[descriptionini description descriptionend];
    descriptionhtml= [descriptionhtml description];
end

%         '	<a class="intrnllnk" href="#outputarg_idx"><code>idx</code></a>\r'...
%         '	= kmeans(<a class="intrnllnk" href="#inputarg_X"><code>X</code></a>\r'...
%         '	,\r'...
%         '   <a class="intrnllnk" href="#inputarg_k"><code>k</code></a>)\r'...



closedescription=sprintf(['								</div>\r'...
    '							</div>\r'...
    '							<div class="clear">\r'...
    '							</div>\r'...
    '						</div>']);

description=[inidescription descriptionhtml closedescription];

%% EXAMPLES
iniexamples=sprintf(['<div class="ref_sect" itemprop="content">\r'...
    '<div class="examples">\r'...
    '<h2 id="examples">Examples</h2>\r'... % start of expandable examples
    '<div id="expandableExamples" class="expandableContent">\r'...
    '<p class="switch"><a class="expandAllLink"' ...
    'href="javascript:void(0);">expand all</a>' ...
    '</p>']);

% start of example j

exampleshtml='';
for j=1:length(sintax)
    exampleshtml=[exampleshtml  sprintf(['<div id="example_' num2str(j) '" class="example_module expandableContent">\r'...
        '<div id="ex' num2str(j) '">\r'...
        '</div>\r'...
        '<h3 class="expand"><span>\r'...
        '<a href="javascript:void(0);" style="display: block;" title="Expand/Collapse">\r'...
        '<span class="example_title">title' num2str(j) '</span></a></span></h3>\r'...
        '<div class="collapse">\r'...
        '<p>xxxx</p>\r'...
        '</div>\r'...
        '</div>\r'])]; % close div id="example_j"
end

closeexamples=sprintf(['</div>\r'... % close div id="expandableExamples
    '<p> </p>\r'... % Related examples are below
    '<h3 class="bottom_ruled">Related Examples</h3>\r'...
    '<ul>\r'...
    '<li>rel1</li>\r'...
    '<li>rel2 </li>\r'...
    '<li>rel3 </li>\r'...
    '</ul>\r'...
    '</div>\r'... % div class="examples"
    '</div>']);	 % close class="ref_sect

examples=[iniexamples exampleshtml closeexamples];

%% INPUT ARGUMENTS
iniinputargs=sprintf(['<div class="ref_sect" itemprop="content">\r'...
    '<h2 id="inputs">Input Arguments</h2>\r'...
    '<div class="expandableContent">\r'...
    '<div class="arguments">\r'...
    '<div class="input_argument_container">\r'...
    '<p class="switch">\r'...
    '<a class="expandAllLink" href="javascript:void(0);">\r'...
    'expand all</a></p>']);

%       inputargs
%[optargs1,optargs2]=regexp(inputargs,'varargin');
%[commasIn] = regexp(inputargs,',');
%if isempty(optargs1)

% in string inpi there will the required input argument


% Write all required input arguments in cell listargins
listargins=cell(nREQargin,1);
for i=1:nREQargin
    if nREQargin>1
        if i==1
            inpi=inputargs(2:commasIn(i)-1);
        else
            inpi=inputargs(commasIn(i-1)+1:commasIn(i)-1);
        end
    else
        if isempty(optargs1) % if there are no optional input arguments
            inpi=inputargs(2:end-1);
        else
            inpi=inputargs(2:commasIn(i)-1);
        end
    end
    listargins{i}=inpi;
end

reqargs='';
for i=1:nREQargin
    
    inpi=listargins{i};
    
    
    insel=regexp(fstring,'Required input arguments:');
    if isempty(insel)
        disp('Please check HTML input file')
        error('FSDA:missInps','HTML file does not contain ''Required input arguments:'' string')
    end
    
    % substring to search start from Required input arguments:
    fstringsel=fstring(insel(1):end);
    inipoint=regexp(fstringsel,[listargins{i} '\s{0,10}:']);
    
    % The endpoint of the substring is See also or the next output argument
    if i <nREQargin
        endpoint=regexp(fstringsel,listargins{i+1});
    else
        endpoint=regexp(fstringsel,'Optional input arguments:');
        if isempty(endpoint)
            disp('Please check HTML input file')
            error('FSDA:missOuts','HTML file does not contain ''Optional input arguments:'' string')
        end
    end
    % descri = string which contains the description of i-th input
    % argument
    descriinput=fstringsel((inipoint(1)+length(listargins{i})+2):endpoint(1)-1);
    
    % Remove from string descri all '% signs
    posPercentageSigns=regexp(descriinput,'%');
    descriinput(posPercentageSigns)=[];
    % Remove from string descri leading and trailing white spaces
    descriinput=strtrim(descriinput);
    % what is before the first comma or the first full stop is the
    % premable, the reset in the description
    posfirstcomma=regexp(descriinput,',','once');
    posfirstfullstop=regexp(descriinput,'\.','once');
    sep=min([posfirstcomma posfirstfullstop]);
    preamble=descriinput(1:sep-1);
    preamble=strtrim(preamble);
    % remove sign : if present at the beginning of the sentence
    if strcmp(preamble(1),':')
        preamble=strtrim(preamble(2:end));
    end
    descriinput=descriinput(sep+1:end);
    % Start with upper case character
    descriinput=strtrim(descriinput);
    descriinput=[upper(descriinput(1)) descriinput(2:end)];
    
    
    % disp(inpi)
    reqargs=[reqargs sprintf(['<div class="expandableContent">\r'...
        '<div id="inputarg_' inpi '" class="clearfix">\r'...
        '</div>\r'...
        '<h3 id="input_argument_' inpi '" class="expand">\r'...
        '<span>\r'...
        '<a href="javascript:void(0);" style="display: block;" title="Expand/Collapse">\r'...
        '<span class="argument_name"><code>' inpi '</code> &#8212; \r'...  % &#8212; = long dash
        'Data</span></a><span class="example_desc">' preamble '</span></span></h3>\r'...
        '<div class="collapse">\r'...
        '<p>' descriinput '</p>\r'...
        '<p class="datatypelist"><strong>\r'...
        'Data Types: </strong><code>single</code> \r'...
        '| <code>double</code></p>\r'...
        '</div>\r'...
        '</div>\r'])];
    
end


% reqargs=sprintf(['<div class="expandableContent">\r'...
% 			'<div id="inputarg_X" class="clearfix">\r'...
% 			'</div>\r'...
% 			'<h3 id="input_argument_X" class="expand">\r'...
% 			'<span>\r'...
% 			'<a href="javascript:void(0);" style="display: block;" title="Expand/Collapse">\r'...
% 			'<span class="argument_name"><code>X</code> &#8212; \r'...  % &#8212; = long dash
% 			'Data</span></a><span class="example_desc">numeric\r'...
% 			'matrix</span></span></h3>\r'...
% 			'<div class="collapse">\r'...
% 				'<p>TOWRITE</p>\r'...
% 				'<p class="datatypelist"><strong>\r'...
% 				'Data Types: </strong><code>single</code> \r'...
% 				'| <code>double</code></p>\r'...
% 			'</div>\r'...
% 		'</div>\r']);



optargs=sprintf(['<div id="namevaluepairarguments" class="clearfix">\r'...
    '</div>\r' ...
    '<h3 id="namevaluepairs" class="bottom_ruled">\r'...
    'Name-Value Pair Arguments</h3>\r'...
    '<div class="namevaluecontainer">\r'...
    '<p>Specify optional comma-separated pairs of <code>Name,Value</code> arguments.\r'...
    ' <code>Name</code> is the argument name and <code>Value</code>\r'...
    ' is the corresponding value. <code>Name</code> must appear \r'...
    ' inside single quotes (<code>'' ''</code>). \r'...
    ' You can specify several name and value pair arguments in any order as <code> \r'...
    ' Name1,Value1,...,NameN,ValueN</code>.</p> \r'...
    ' <span class="example_desc"><strong>Example:\r'...
    '</strong><code>''Distance'',''cosine'',''Replicates'',10,''Options'',statset(''UseParallel'',1)</code>\r'...
    'specifies xxxxxxxxxx</span></div>']);


optargsexp=sprintf(['<div class="expandableContent">\r'...
    '<div id="inputarg_Display" class="clearfix">\r'...
    '</div>\r'...
    '<h3 id="input_argument_namevalue_display" class="expand">\r'...
    '<span>\r'...
    '<a href="javascript:void(0);" style="display: block;" title="Expand/Collapse">\r'...
    '<span class="argument_name"><code>''Display''</code> &#8212;\r'...
    'Level of output to display</span></a><span class="example_desc"><code>''off''</code>\r'...
    '(default) | <code>''final''</code> |	<code>''iter''</code></span></span></h3>\r'...
    '<div class="collapse">\r'...
    '	<p>Level of output to display in \r'...
    '	the Command Window, specified as \r'...
    '	the comma-separated pair consisting\r'...
    '	of <code>''Display''</code> and a \r'...
    '	string. Available options are:</p>\r'...
    '	<ul type="disc">\r'...
    '		<li>\r'...
    '		<p><code>''xxx''</code> &#8212;\r'...
    '		xxxx</p>\r'...
    '		</li>\r'...
    '		<li>\r'...
    '		<p><code>''yyyy''</code> &#8212;\r'...
    '		yyyyy</p>\r'...
    '		</li>\r'...
    '		<li>\r'...
    '	</ul>\r'...
    '	<p class="description_valueexample">\r'...
    '	<strong>Example: </strong><code>\r'...
    '	''Display'',''final''</code></p>\r'...
    '	<p class="datatypelist"><strong>\r'...
    '	Data Types: </strong><code>char</code></p>\r'...
    '</div>\r'...
    '</div>']);

% CLOSE OPT ARGS

closeoptargs=sprintf(['</div>\r'...
    '</div>\r'...
    '</div>\r'...
    '</div>\r']);
inputargs=[iniinputargs reqargs  optargs optargsexp closeoptargs];


%% OUTPUT ARGUMENTS

inioutargs=sprintf(['<div class="ref_sect" itemprop="content">\r'...
    '<h2>Output Arguments</h2>\r'...
    '<div class="expandableContent">\r'...
    '<div class="arguments">\r'...
    '<div class="output_argument_container">\r'...
    '<p class="switch">\r'...
    '<a class="expandAllLink" href="javascript:void(0);">expand all</a></p>']);

% outargs = strings which contains output arguements (includeing [])
% nargout = number of output arguments
outargshtml='';
for i=1:nargout
    %     if nargout>1
    %             if i==1
    %                 outi=outs(2:commasOut(i)-1);
    %             elseif i==nargout
    %                 outi=outs(commasOut(i-1)+1:end-1);
    %             else
    %                 outi=outs(commasOut(i-1)+1:commasOut(i)-1);
    %             end
    %     else
    %         outi=outs;
    %     end
    
    % listargouts is a cell which contains the list of output arguments
    outi=listargouts{i};
    
    outsel=regexp(fstring,'Output:');
    if isempty(outsel)
        disp('Please check HTML input file')
        error('FSDA:missOuts','HTML file does not contain ''Output:'' string')
    end
    
    % substring to search start from Output:
    fstringsel=fstring(outsel(1):end);
    inipoint=regexp(fstringsel,[listargouts{i} ':']);
    
    % The endpoint of the substring is See also or the next output argument
    if i <nargout
        endpoint=regexp(fstringsel,listargouts{i+1});
    else
        endpoint=regexp(fstringsel,'See also');
        if isempty(endpoint)
            disp('Please check HTML input file')
            error('FSDA:missOuts','HTML file does not contain ''See alsot:'' string')
        end
    end
    % descri = string which contains the description of i-th output
    % argument
    descrioutput=fstringsel((inipoint(1)+length(listargouts{i})+2):endpoint(1)-1);
    
    % Remove from string descri all '% signs
    posPercentageSigns=regexp(descrioutput,'%');
    descrioutput(posPercentageSigns)=[];
    % Remove from string descri leading and trailing white spaces
    descrioutput=strtrim(descrioutput);
    
    % Check if string descri contains the words 'which contains' or
    % 'containing';
    poswhichcontains=regexp(descrioutput,'which contains');
    if ~isempty(poswhichcontains) && poswhichcontains(1)<120
        preamble=descrioutput(1:poswhichcontains(1)-1);
        descrioutput=descrioutput(poswhichcontains(1)+14:end);
        % Remove word the at the beginning of the sentence and starts with
        % uppercase
        StartsWithThe=regexp(descrioutput,'the');
        if StartsWithThe(1)<4
            descrioutput=descrioutput(StartsWithThe(1)+4:end);
        end
        descrioutput=strtrim(descrioutput);
        descrioutput=[upper(descrioutput(1)) descrioutput(2:end)];
    else
        poscontaining=regexp(descrioutput,'containing');
        if ~isempty(poscontaining) && poscontaining(1)<120
            preamble=descrioutput(1:poscontaining(1)-1);
            descrioutput=descrioutput(poscontaining(1)+10:end);
            % Remove word the at the beginning of the sentence and starts with
            % uppercase
            StartsWithThe=regexp(descrioutput,'the');
            if StartsWithThe(1)<4
                descrioutput=descrioutput(StartsWithThe(1)+4:end);
            end
            descrioutput=strtrim(descrioutput);
            descrioutput=[upper(descrioutput(1)) descrioutput(2:end)];
        else
            preamble='TOWRITE';
        end
    end
    % transform x with by and write in italic the dimensions of the
    % matrices
    if ~strcmp(preamble,'TOWRITE')
        
        outvect=regexp(preamble,'\wector', 'once');
        if ~isempty(outvect)
            beforepreamble=preamble(1:outvect-1);
            beforepreamble=strrep(beforepreamble, 'x', '-by-');
            preamble=['<code>' beforepreamble  '</code>' preamble(outvect:end)];
        end
        
        
        outmat=regexp(preamble,'\watrix', 'once');
        if ~isempty(outmat)
            beforepreamble=preamble(1:outmat-1);
            beforepreamble=strrep(beforepreamble, 'x', '-by-');
            preamble=['<code>' beforepreamble '</code>' preamble(outmat:end)];
        end
    end
    
    preamble=strtrim(preamble);
    
    outargshtml=sprintf([outargshtml sprintf(['<div class="expandableContent">\r'...
        '<div id="outputarg_' outi '" class="clearfix">\r'...
        '</div>\r'...
        '<h3 id="output_argument_' outi '" class="expand">\r'...
        '<span>\r'...
        '<a href="javascript:void(0);" style="display: block;" title="Expand/Collapse">\r'...
        '<span class="argument_name"><code>' outi '</code> &#8212; description</span></a>\r'...
        '<span class="example_desc">' preamble '</span></span></h3>\r'...
        '<div class="collapse">\r'...
        '<p>' descrioutput '</p>\r'...
        '</div>\r'...
        '</div>'])]);
    
end

closeoutargs=sprintf(['</div>\r'...
    '</div>\r'...
    '</div>\r'...
    '</div>']);


outargs=[inioutargs outargshtml closeoutargs];

%% MORE ABOUT SECTION

Moreabout=sprintf(['<div class="moreabout ref_sect">\r'...
    '<h2 id="moreabout">More About</h2>\r'...
    '<div class="expandableContent">\r'...
    '<p class="switch">\r'...
    '<a class="expandAllLink" href="javascript:void(0);">\r'...
    'expand all</a></p>\r'...
    '<div class="expandableContent" itemprop="content">\r'...
    '<h3 class="expand"><span>\r'...
    '<a href="javascript:void(0);" style="display: block;" title="Expand/Collapse">\r'...
    '<span>ADDITIONAL EXAMPLE</span></a></span></h3>\r'...
    '<div class="collapse">\r'...
    '<p>describe describe </p>\r'...
    '</div>\r'...
    '</div>\r'...
    '</div>\r'...
    '</div>']);

%% REFERENCES
References=sprintf(['<div class="ref_sect" itemprop="content">\r'...
    '<div class="bibliography">\r'...
    '<h2 id="references">References</h2 \r'...
    '<div> \r'...
    '	<p>XXXXXX</p>\r'...
    '</div>\r'...
    '<div> \r'...
    '	<p>YYYYYY</p>\r'...
    '</div>\r'...
    '</div>\r'...
    '</div>']);

%% SEE ALSO

Seealso=sprintf(['<div class="ref_sect">\r'...
    '<h2>See Also</h2>\r'...
    '<p>\r'...
    '<span itemprop="seealso">\r'...
    '<a href="clusterdata.html" itemprop="url">\r'...
    '<span itemprop="name"><code>clusterdata</code></span></a></span>\r'...
    '|\r'...
    '<span itemprop="seealso">\r'...
    '<a href="gmdistribution-class.html" itemprop="url">\r'...
    '<span itemprop="name"><code>gmdistribution</code></span></a></span> \r'...
    '|\r'...
    '<span itemprop="seealso">\r'...
    '<a href="linkage.html" itemprop="url">\r'...
    '<span itemprop="name"><code>linkage</code></span></a></span> \r'...
    '</div>']);


%% CLOSE TAGS SECTION

clos=sprintf(['<h1>Automatically generated by FSDA parser</h1>\r'...
    '</div>\r'...
    '</section>\r'...
    '</div>\r'...
    '</div>\r'...
    '</div>\r'...
    '</div>\r'...
    '</body>'...
    '</html>']);



out=fstring;
fclose(fileID);

outstring=([titl metacontent sitecont sintaxhtml sintaxclose description  ....
    examples inputargs outargs Moreabout References Seealso clos]);


file1ID=fopen([name 'tmp.html'],'w');
fprintf(file1ID,'%s',outstring);
fclose('all');


end
