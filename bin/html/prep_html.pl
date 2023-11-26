#!/usr/bin/perl
use warnings;
use Cwd;

my $outdir = shift;
my $pop_dir = "./04_Population/";
my $param_dir = "./param/";
my $out_html = $outdir."/index.html";
`touch $out_html`;
chmod(0744,$out_html);
open(FW,">$out_html");

opendir(my $dir, $pop_dir);
my @date_list = readdir($dir);
closedir($dir);

my %hs_lev2_analysis = ("PCA"=>0,"MSMC"=>0,"Treemix"=>0,"Plink2"=>0,"AdmixtureProportion"=>1,"Fst"=>1,"Structure"=>0,"EffectiveSize"=>0,"PhylogeneticTree"=>2,"SweepFinder2"=>1,"LdDecay"=>1);
my %hs_analysis_name = ("PCA"=>	"Principal component analysis_Plink v.1.9",
                        "Plink2"=>	"Principal component analysis_Plink v.2.0",
                        "PhylogeneticTree"=>	"Phylogenetic analysis",
                        "Treemix"=>	"Population trsee analysis",
                        "Structure"=>	"Population structure analysis",
                        "LdDecay"=>	"Linkage disequilibrium decay analysis",
                        "SweepFinder2"=>	"Selective sweep analysis",
                        "AdmixtureProportion"=>	"Population admixture analysis",
                        "MSMC"=>	"Multiple sequentially Markovian coalescent analysis",
                        "EffectiveSize"=>	"Pairwise sequentially Markovian coalescent analysis",
                        "Fst"=>	"Fixation index analysis");

print FW '<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.1/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-4bw+/aepP/YC94hEpVNVgiZdgIC5+VKNBQNGCHeKRQN+PtmoHDEXuppvnDJzQIu9" crossorigin="anonymous">
        <style>
            p{
                margin: 0 auto; 
            }
            .par_iframe{
                width:960px;
                height:300px;
            }
            .pdf_iframe{
                width:960px;
                height:900px;
                margin-top: 10px; 
            }
            body {
                width: 960px; 
                margin: 0 auto; 
            }
            .hidden {
                display: none;
            }
            .analysis {
                width:960px;
            }
            .lev2{
                width:200px;
            }
        </style>
        <title>PAPipe result browser </title>
    </head>
    <body class="bg-light">
        <div style="text-align: center;">
            <h3 style="margin-top: 20px; margin-bottom: 30px;">Visualization of the analysis results by PAPipe</h3>
            <div style="text-align: center;">
                <label for="dateSelect">Date : </label>
                <select id="dateSelect" style="width: 200px; margin-bottom: 20px;" onchange="showHideDateSelect()">'."\n";
foreach my $date (@date_list){
    if($date =~ /^\./){next;}
    print FW  '                    <option value='.$date.'>'.$date.'</option>'."\n";
}
print FW  '                </select>'."\n";
print FW '                <label for="analysisSelect_div" style="margin-left: 20px;">Analysis : </label>
                <div id="analysisSelect_div" style="display: inline;">'."\n";
my $date_cnt = 0;
my $print_analysis = "";
foreach my $date (@date_list){
    if($date =~ /^\./){next;}
    opendir my $dir, "$pop_dir/$date";
    my @analysis_list = readdir($dir);
    closedir($dir);
    my $selectID = "$date\_select";
    if ($date_cnt==0){
        print FW  '                    <select id='.$selectID.' style="width: 410px; margin-bottom: 20px;" onchange="showHideAnalysisSelect(this.id, this.value)">';
    }else{
        print FW  '                    <select id='.$selectID.' style="width: 410px; margin-bottom: 20px;" class="hidden" onchange="showHideAnalysisSelect(this.id, this.value)">';
    }
    foreach my $analysis (@analysis_list){
        if($analysis =~ /^\./){next;}
        $print_analysis = $hs_analysis_name{$analysis};
        print FW  '                        <option value='.$analysis.'>'.$print_analysis.'</option>'."\n";
    }
    print FW  '                    </select>'."\n";

    $date_cnt++;
}
print FW '               </div>
            </div>
        </div>
        <div id="Allresults_div" style="text-align: center;">'."\n";

$date_cnt = 0;
foreach my $date (@date_list){
    if($date =~ /^\./){next;}
    opendir my $dir, "$pop_dir/$date";
    my @analysis_list = readdir($dir);
    closedir($dir);
    my $divID = "$date\_results";
    if ($date_cnt==0){
        print FW  '            <div id='.$divID.' class="results">'."\n";
    }else{
        print FW  '            <div id='.$divID.' class="results hidden">'."\n";
    }
    my $analysis_cnt=0;
    foreach my $analysis (@analysis_list){
        if($analysis =~ /^\./){next;}
        $print_analysis = $hs_analysis_name{$analysis};
        my $analysisDivID = "$date\_select_$analysis";
        if ($analysis_cnt==0){
            print FW  '                <div id='.$analysisDivID.'  class="analysis">'."\n";
        }else{
            print FW  '                <div id='.$analysisDivID.' class="hidden analysis">'."\n";
        }
        my $lev2_flag = $hs_lev2_analysis{$analysis};
        my $param_path = "$param_dir/$date/$analysis.txt";
        #my $result_path_print1 = abs_path("$pop_dir/$date/$analysis/");
        my $result_path_print1 = "$pop_dir/$date/$analysis/";
        my $result_path_print2 = "[Local_web directory path]/04_Population/$date/$analysis/";
        my $result_path = "$pop_dir/$date/$analysis/";
        if ($analysis eq "Structure"){
            $result_path_print1.="CLUMPAK/";
            $result_path_print2.="CLUMPAK/";
            $result_path.="CLUMPAK/";
        }
        
        if ($lev2_flag == 0){
            opendir (my $dir, $result_path);
            my @analysis_list = readdir($dir);
            closedir($dir);
            $result_path_print1 .= $analysis_list[2];
            $result_path_print2 .= $analysis_list[2];
            $result_path .= $analysis_list[2];
            print FW  '                    <h5 style="text-align: left;">'.$print_analysis.'</h5>'."\n";
            print FW  '                    <div>
                        <details style="text-align: left;">
                            <summary>Parameters</summary>
                            <iframe class="par_iframe" src='.$param_path.'></iframe>    
                        </details>
                    </div>
                    <div>
                        <p style="text-align: left;"> Server path: '."$result_path_print1".'</p>
                        <p style="text-align: left;"> Local path: '."$result_path_print2".'</p>
                        <iframe class="pdf_iframe" src='.$result_path.'></iframe>
                    </div>'."\n";
        }elsif($lev2_flag == 1){
            my $select_id = $date."_".$analysis."_select";
            print FW  '                    <h5 style="text-align: left;">'.$print_analysis.'</h5>'."\n";
            print FW  '                    <div style="text-align: left;">
                        <details>
                            <summary>Parameters</summary>
                            <iframe class="par_iframe" src='.$param_path.'></iframe>    
                        </details>
                        <select style="text-align: left;" id='.$select_id.' style="width: 200px;" onchange="showHideLev2Select(this.id, this.value)">'."\n";
            opendir(my $dir, $result_path);
            my @resDir_list = readdir($dir);
            closedir($dir);

            foreach my $diffRes (@resDir_list){
                if($diffRes =~ /^\./){next;}
                if ($analysis eq "LdDecay"){
                print FW  '                            <option value='.$diffRes.'> MaxDist: '.$diffRes.'</option>'."\n";
                }else{
                print FW  '                            <option value='.$diffRes.'>'.$diffRes.'</option>'."\n";
                }
            }
            print FW  '                        </select>
                    </div>
                    <div id="diffResContainer'."_$select_id".'">'."\n";
            
            my $diffResCnt=0;
            foreach my $diffRes (@resDir_list){
                if($diffRes =~ /^\./){next;}

                my $lev2_result_path_print1 = "$pop_dir/$date/$analysis/$diffRes/";
                my $lev2_result_path_print2 = "[Local_web directory path]/04_Population/$analysis/$diffRes/";
                my $lev2_result_path = "$result_path/$diffRes/";

                if ($analysis eq "LdDecay"){
                    $lev2_result_path_print1 .= "/Plot/";
                    $lev2_result_path_print2 .= "/Plot/";
                    $lev2_result_path .= "/Plot/";
                }
                opendir(my $dir, $lev2_result_path );
                my @result = readdir($dir);
                closedir($dir);
                
                $lev2_result_path_print1 .= "$result[2]";
                $lev2_result_path_print2 .= "$result[2]";
                $lev2_result_path .= "$result[2]";

                my $lev2ResDivID = $select_id."_".$diffRes;
                if ($diffResCnt==0){
                    print FW  '                        <div class="div_lev2" id='.$lev2ResDivID.'>'."\n";
                }else{
                    print FW  '                        <div class="div_lev2 hidden" id='.$lev2ResDivID.'>'."\n";
                }
                print FW '                            <p style="text-align: left;"> Server path: '."$lev2_result_path_print1".'</p>
                            <p style="text-align: left;"> Local path: '."$lev2_result_path_print2".'</p>
                            <iframe class="pdf_iframe"  src='.$lev2_result_path.'></iframe>
                        </div>'."\n";
                $diffResCnt++;
            }
            print FW  "                    </div>\n";            
        }else{ #tree
            opendir (my $dir, $result_path);
            my @analysis_list = readdir($dir);
            closedir($dir);
            my $result_path_tree = $result_path."/snphylo.ml.tree";
            my $result_path_pdf = $result_path."/Rplots.pdf";
            print FW  '                    <h5 style="text-align: left;">'.$print_analysis.'</h5>'."\n";
            print FW  '                    <div>
                        <details style="text-align: left;">
                            <summary>Parameters</summary>
                            <iframe class="par_iframe" src='.$param_path.'></iframe>    
                        </details>
                    </div>
                    <div>
                        <p style="text-align: left;"> Server path: '."$result_path_print1".'</p>
                        <p style="text-align: left;"> Local path: '."$result_path_print2".'</p>
                        <details style="text-align: left;">
                            <summary>Newick Tree</summary>
                            <iframe class="par_iframe" src='.$result_path_tree.'></iframe>
                        </details>
                        <iframe class="pdf_iframe" src='.$result_path_pdf.'></iframe>
                    </div>'."\n";
        }        
        #print FW  "$outdir/$date/$analysis\n";
        print FW  '                </div>'."\n";
        $analysis_cnt++
    }
    print FW  '            </div>'."\n";

    $date_cnt++;
}



        print FW  '        </div>
    </body> 
    <script>
        function showHideDateSelect() {
            var mainSelect = document.getElementById("dateSelect");
            var selectContainer = document.getElementById("analysisSelect_div");
            var selectContainer_results = document.getElementById("Allresults_div");

            var selects = selectContainer.getElementsByTagName("select");
            for (var i = 0; i < selects.length; i++) {
                selects[i].classList.add("hidden");
            }
            var selects = selectContainer_results.getElementsByClassName("results");
            for (var i = 0; i < selects.length; i++) {
                selects[i].classList.add("hidden");
            }

            var selectedValue = mainSelect.value;
            var selectedOption = document.getElementById(selectedValue+"_select");
            if (selectedOption) {
                selectedOption.classList.remove("hidden");
            }
            var selectedOption = document.getElementById(selectedValue+"_results");
            if (selectedOption) {
                selectedOption.classList.remove("hidden");
            }
        }
        function showHideAnalysisSelect(cur_date_id, cur_select_value) {
            var date = document.getElementById("dateSelect");
            var showResDivId = cur_date_id+"_"+cur_select_value;
            var selectContainer = document.getElementById(date.value+"_results");
            var selects = selectContainer.getElementsByClassName("analysis");
            for (var i = 0; i < selects.length; i++) {
                selects[i].classList.add("hidden");
            }
            var selectedOption = document.getElementById(showResDivId);
            if (selectedOption) {
                selectedOption.classList.remove("hidden");
            }
        }
        function showHideLev2Select(cur_select_id, cur_select_value) {
            var showResDivId = cur_select_id+"_"+cur_select_value;
            
            var selectContainer = document.getElementById("diffResContainer_"+cur_select_id);
            var selects = selectContainer.getElementsByClassName("div_lev2");
            for (var i = 0; i < selects.length; i++) {
                selects[i].classList.add("hidden");
            }
            var selectedOption = document.getElementById(showResDivId);
            if (selectedOption) {
                selectedOption.classList.remove("hidden");
            }
        }
        
    </script>
</html>
';
close(FW);
