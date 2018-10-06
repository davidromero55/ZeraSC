package Zera::AdminSC::Actions;

use strict;
use JSON;
use base 'Zera::BaseAdmin::Actions';

sub do_brands_edit {
    my $self = shift;
    my $results = {};

    $self->param('brand_id',0) if($self->param('brand_id') eq 'New');

    if($self->param('_submit') eq 'Save'){
        # Prevent URL duplicates
        my $exist = $self->selectrow_array(
            "SELECT COUNT(*) FROM sc_brands WHERE name=? AND brand_id<>?",{},$self->param('name'), int($self->param('brand_id'))) || 0;
        if($exist){
            my $base_name = $self->param('name');
            for (my $i = 1; $i < 1000; $i++){
                $self->param('name',$base_name . '-'.$i);
                $exist = $self->selectrow_array(
                    "SELECT COUNT(*) FROM sc_brands WHERE name=? AND brand_id<>?",{},$self->param('name'), int($self->param('brand_id'))) || 0;
                last if ($exist == 0);
            }
        }

        my $display_options = {};
        my $image = $self->upload_file('image', 'img');
        if($image){
            $display_options->{image} = '/data/img/'.$image;
        }

        eval {
            if(int($self->param('brand_id'))){
                # Update
                $self->dbh_do("UPDATE sc_brands SET name=?, active=?, description=? " .
                                 " WHERE brand_id=?",{},
                                 $self->param('name'), int($self->param('active')), $self->param('description'),$self->param('brand_id'));
               if($image){
                 my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_brands WHERE brand_id = ?", {}, $self->param('brand_id'));
                 $self->add_msg("info", $oldimage->{image});
                 unlink "data/img/$oldimage->{image}" if($oldimage->{image});
                 $self->dbh_do("UPDATE sc_brands SET image=? " .
                                  " WHERE brand_id=?",{},
                                  $image, $self->param('brand_id'));
               }
            }else{
                # Insert
                $self->dbh_do("INSERT INTO sc_brands (name,image, active, description) " .
                                 "VALUES (?,?,?,?)",{},
                                 $self->param('name'), $image, int($self->param('active')), $self->param('description'));
            }
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/Brands';
            $results->{success} = 1;
            return $results;
        }
    }elsif($self->param('_submit') eq 'Delete'){
        eval {
            my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_brands WHERE brand_id = ?", {}, $self->param('brand_id'));
            $self->add_msg("info", $oldimage->{image});
            unlink "data/img/$oldimage->{image}" if($oldimage->{image});
            $self->dbh_do("DELETE FROM sc_brands  WHERE brand_id=?",{},
                             $self->param('brand_id'));
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/Brands';
            $results->{success} = 1;
            return $results;
        }

    }elsif($self->param('_submit') eq 'Delete Logo'){
        eval {
            my $oldimage = $self->selectrow_hashref("SELECT image FROM sc_brands WHERE brand_id = ?", {}, $self->param('brand_id'));
            $self->add_msg("info", $oldimage->{image});
            unlink "data/img/$oldimage->{image}" if($oldimage->{image});
            $self->dbh_do("UPDATE sc_brands  SET image='' WHERE brand_id=?",{},
                             $self->param('brand_id'));
        };
        if($@){
            $self->add_msg('warning','Error '.$@);
            $results->{error} = 1;
            return $results;
        }else{
            $results->{redirect} = '/AdminSC/BrandsEdit/'.$self->param('brand_id');
            $results->{success} = 1;
            return $results;
        }

    }


}


1;
