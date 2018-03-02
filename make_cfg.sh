#!/bin/bash

echo "starting kube-cfg..."
#USAGE
# ./make_config.sh "clustnerendpoint.com" "cluster-name" "~/path/ssh/id_rsa" 30

if [[ -z "$1" ]]; then
   echo "Cluster endpoint required" && exit 1
fi

if [[ -z "$2" ]]; then
   echo "Cluster name required" && exit 1
fi

if [[ -z "$3" ]]; then
   echo "SSH key required" && exit 1
fi

if [[ -z "$4" ]]; then
   echo "Expiry in days (int) required" && exit 1
fi


clusterendpoints=$1
clusternames=$2
ssh_key=$3
expirydays=$4

outputdir=/data/configs

username="cluster-admin"
namespace=default
IFS=', ' read -r -a endpoints <<< "$clusterendpoints"
IFS=', ' read -r -a clusters <<< "$clusternames"


mkdir -p $outputdir

fetch_certs(){

    local GEN_CLUSTER_ENDPOINTS=$1
    local GEN_CLUSTER_NAMES=$2

    IFS=', ' read -r -a endpoints <<< "$GEN_CLUSTER_ENDPOINTS"
    IFS=', ' read -r -a clusters <<< "$GEN_CLUSTER_NAMES"

    #Grab the CA certs from the masters for processing...
    for c in "${endpoints[@]}"
    do  
        :
        endpoint=${endpoints[$i]}
        cluster=${clusters[$i]}

        echo "Processing endpoint : $endpoint"
        echo "Processing cluster name: $cluster"
        
        ssh -o "StrictHostKeyChecking no" -i $ssh_key azureuser@${endpoint} sudo mkdir -p /usr/local/certs
        ssh -o "StrictHostKeyChecking no" -i $ssh_key azureuser@${endpoint} sudo chmod +777 /usr/local/certs
        ssh -o "StrictHostKeyChecking no" -i $ssh_key azureuser@${endpoint} sudo cp /etc/kubernetes/certs/ca.key /usr/local/certs/ca.key
        ssh -o "StrictHostKeyChecking no" -i $ssh_key azureuser@${endpoint} sudo chmod +777 /usr/local/certs/ca.key
        mkdir -p $outputdir/${cluster}
        scp -o "StrictHostKeyChecking no" -i $ssh_key azureuser@${endpoint}:/etc/kubernetes/certs/ca.crt $outputdir/${cluster}/ca.crt
        scp -o "StrictHostKeyChecking no" -i $ssh_key azureuser@${endpoint}:/usr/local/certs/ca.key $outputdir/${cluster}/ca.key
        ssh -o "StrictHostKeyChecking no" -i $ssh_key azureuser@${endpoint} sudo rm /usr/local/certs/ca.key

        i=$((i+1))
    done
}

generate(){
    local GEN_CLUSTER_ENDPOINTS=$1
    local GEN_USER_NAME=$2
    local GEN_CLUSTER_NAMES=$3
    local GEN_NAMESPACE=$4
    local GEN_EXPIRYINDAYS=$5
    
    IFS=', ' read -r -a endpoints <<< "$GEN_CLUSTER_ENDPOINTS"
    IFS=', ' read -r -a clustersArr <<< "$GEN_CLUSTER_NAMES"
    generatecounter=0

    for c in "${endpoints[@]}"
    do
        :
        GEN_CLUSTER_ENDPOINT=${endpoints[$generatecounter]}
        GEN_CLUSTER_NAME=${clustersArr[$generatecounter]}
        echo "Processing endpoint : $GEN_CLUSTER_ENDPOINT"
        echo "Processing cluster name: $GEN_CLUSTER_NAME"

        folder=$outputdir/$GEN_CLUSTER_NAME
        mkdir -p $folder
        KUBECONFIG=$folder/config
       
        openssl genrsa -out $folder/client.key 4096
        openssl req -new -key $folder/client.key -out $folder/client.csr -subj "/C=AU/ST=Melbourne/L=Melbourne/O=Kubernetes Security/OU=$GEN_NAMESPACE/CN=$GEN_USER_NAME"
        openssl x509 -req -days $GEN_EXPIRYINDAYS -in $folder/client.csr -CA $outputdir/${GEN_CLUSTER_NAME}/ca.crt -CAkey $outputdir/${GEN_CLUSTER_NAME}/ca.key -set_serial 01 -out $folder/client.crt

        kubectl config --kubeconfig=$KUBECONFIG set-cluster $GEN_CLUSTER_NAME --embed-certs=true --server=https://$GEN_CLUSTER_ENDPOINT --certificate-authority=$outputdir/${GEN_CLUSTER_NAME}/ca.crt
        kubectl config --kubeconfig=$KUBECONFIG set-credentials "$GEN_CLUSTER_NAME-$GEN_USER_NAME" --client-certificate=$folder/client.crt --embed-certs=true --client-key $folder/client.key
        kubectl config --kubeconfig=$KUBECONFIG set-context $GEN_CLUSTER_NAME --cluster=$GEN_CLUSTER_NAME --user="$GEN_CLUSTER_NAME-$GEN_USER_NAME" --namespace=$GEN_NAMESPACE
        kubectl config --kubeconfig=$KUBECONFIG use-context $GEN_CLUSTER_NAME
        kubectl get nodes --kubeconfig=$KUBECONFIG
        
        cp $folder/config $folder/${GEN_CLUSTER_NAME}.config
        generatecounter=$((generatecounter+1))
        echo "generatecounter = $generatecounter"
    done
}

fetch_certs "$clusterendpoints" "$clusternames"
generate "$clusterendpoints" "$username"  "$clusternames" "$namespace" $expirydays