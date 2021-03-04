

outputdir = "phage_finder_tests"


include: "../scripts/preflight.smk"


rule all:
    input:
        expand(os.path.join(outputdir, "{genome}_phage_finder", "{genome}_phage_finder_tptn.tsv"), genome=GENOMES)


rule run_phage_finder:
    input:
        fna = os.path.join(outputdir, "{genome}_phage_finder", "{genome}.fna"),
        faa = os.path.join(outputdir, "{genome}_phage_finder", "{genome}.faa"),
        pfi = os.path.join(outputdir, "{genome}_phage_finder", "phage_finder_info.txt"),
    output:
        os.path.join(outputdir, "{genome}_phage_finder", "PFPR_tab.txt")
    params:
        wd = os.path.join(outputdir, "{genome}_phage_finder"),
        pr = "{genome}"
    benchmark:
        os.path.join(outputdir, "benchmarks", "{genome}_phage_finder.txt")
    conda:
        "../conda_environments/phage_finder.yaml"
    shell:
        """
        cd {params.wd} && touch error.log formatdb.log && /home3/redwards/opt/phage_finder/phage_finder_v2.1/bin/phage_finder_v2.1.sh {params.pr}
        """

rule phage_finder_to_tbl:
    input:
        tsv = os.path.join(outputdir, "{genome}_phage_finder", "PFPR_tab.txt")
    output:
        os.path.join(outputdir, "{genome}_phage_finder", "{genome}_phage_finder_locs.tsv")
    shell:
        """
        set +e
        G=$(grep -v ^# {input.tsv})
        exitcode=$?
        if [ $exitcode == 0 ]; then
            IFS=$"\n"
            for X in $(echo $G); do 
                echo $X | cut -f 1,4,5 > {output}
            done
        elif [ $exitcode == 1 ]; then
            touch {output}
        else
            exit $exitcode
        fi
        """

rule count_tp_tn:
    input:
        gen = os.path.join(test_genomes, "{genome}.gb.gz"),
        tbl = os.path.join(outputdir, "{genome}_phage_finder", "{genome}_phage_finder_locs.tsv")
    output:
        tp = os.path.join(outputdir, "{genome}_phage_finder", "{genome}_phage_finder_tptn.tsv")
    shell:
        """
        python3 scripts/compare_predictions_to_phages.py -t {input.gen} -r {input.tbl} > {output.tp}
        """
